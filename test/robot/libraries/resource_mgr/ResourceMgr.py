# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2020 Intel Corporation
from robot.api import logger
from robot.libraries.BuiltIn import BuiltIn
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker

from base import Base
from vmmac import VmMac


# Hook for SQLite 'connect' signal
def _sqlite_connect(dbapi_connection, connection_record):
    # disable pysqlite's emitting of the BEGIN statement entirely.
    # also stops it from emitting COMMIT before any DDL.
    dbapi_connection.isolation_level = None

# Hook for SQLite 'begin' signal
def _sqlite_begin(conn):
    # Emit BEGIN EXCLUSIVE to lock the DB to avoid non-atomic read-and-writes in SQLite.
    conn.execute("BEGIN EXCLUSIVE")


_utils_lib = BuiltIn().get_library_instance("Utils")


class ResourceMgr(object):
    """Resource management class.

    Before starting to use ResourceMgr, connect(**db_conf) must be called to set up a connection to DB.
    """

    ROBOT_LIBRARY_SCOPE = 'TEST SUITE'


    def __init__(self):
        self._engine = None
        self._Session = None

    @_utils_lib.retry_decorator(count=5, sleep_interval=1)
    def connect(self, **db_conf):
        """Connect to a DB using configuration from db_conf.

        **db_conf takes the following options:
        :param str backend: Specifies particular DB backend. Supported values: 'sqlite'
        :param str url: DB URL. In case of SQLite it's a path to DB file.

        :raises sqlalchemy.exc.OperationalError: Raised when DB is locked by another client.
        """
        if db_conf['backend'] == 'sqlite':
            url = db_conf['url']
            self._engine = create_engine('sqlite:///{}'.format(url))

            logger.info('Connected to SQLite DB: {}'.format(url))

            event.listen(self._engine, "connect", _sqlite_connect)
            event.listen(self._engine, "begin", _sqlite_begin)
        else:
            raise ValueError('Unsupported DB backend!: {}'.format(db_conf['backend']))

        Base.metadata.create_all(self._engine)
        self._Session = sessionmaker(self._engine)

    @_utils_lib.retry_decorator(count=5, sleep_interval=1)
    def add_vm_mac(self, address, bridge, in_use):
        """Add VM MAC address.

        :param str address: MAC address.
        :param str bridge: Bridge used as a network source for a given MAC.
        :param bool in_use: Determines whether MAC is currently in use.
        """
        mac = VmMac(address=address, bridge=bridge, in_use=in_use)
        try:
            session = self._Session()
            logger.debug("add_vm_mac({}, {}, {}) DB LOCK".format(address, bridge, in_use))

            session.add(mac)
            session.commit()

            logger.debug("add_vm_mac({}, {}, {}) DB UNLOCK".format(address, bridge, in_use))
            logger.info("Added VM MAC to DB: address='{}', bridge='{}', is_use='{}'".format(address, bridge, in_use))
        except Exception as e:
            session.rollback()
            logger.debug("add_vm_mac({}, {}, {}) DB UNLOCK".format(address, bridge, in_use))
            raise e

    @_utils_lib.retry_decorator(count=5, sleep_interval=1)
    def return_vm_mac_to_pool(self, address, bridge):
        """Return VM MAC to the pool of available addresses.

        :param str address: MAC address.
        :param str bridge: Bridge used as a network source for a given MAC.
        """
        try:
            session = self._Session()
            logger.debug("return_vm_mac_to_pool({}, {}) DB LOCK".format(address, bridge))

            query = session.query(VmMac).with_for_update(nowait=True).filter_by(address=address, bridge=bridge, in_use=True)
            if query.count() != 1:
                raise LookupError('Expected exactly one MAC address, got {}'.format(query.count()))
            mac = query.first()
            mac.in_use = False
            session.commit()

            logger.debug("return_vm_mac_to_pool({}, {}) DB UNLOCK".format(address, bridge))
            logger.info("Returned VM MAC to the Pool: address='{}', bridge='{}'".format(address, bridge))
        except Exception as e:
            session.rollback()
            logger.debug("return_vm_mac_to_pool({}, {}) DB UNLOCK".format(address, bridge))
            raise e

    @_utils_lib.retry_decorator(count=5, sleep_interval=1)
    def get_free_vm_mac(self, bridge):
        """Finds one unused MAC address, marks it as used and returns it.

        :param str bridge: Bridge used as a network source for a MAC.

        :return: Unused MAC address.
        :raises LookupError: Raised when no free addresses are available.
        :raises sqlalchemy.exc.OperationalError: Raised when DB is locked by another client.
        """
        try:
            session = self._Session()
            logger.debug("get_free_vm_mac({}) DB LOCK".format(bridge))

            query = session.query(VmMac).with_for_update(nowait=True).filter_by(bridge=bridge, in_use=False)
            if query.count() == 0:
                raise LookupError('All MAC addresses are in use!')
            free_mac = query.first()
            free_mac.in_use = True
            address = free_mac.address
            session.commit()

            logger.debug("get_free_vm_mac({}) DB UNLOCK".format(bridge))
            logger.info("Found free MAC: address='{}', bridge='{}'".format(address, bridge))

            return address
        except Exception as e:
            session.rollback()
            logger.debug("get_free_vm_mac({}) DB UNLOCK".format(bridge))
            raise e
