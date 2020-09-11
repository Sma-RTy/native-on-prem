from sqlalchemy import Boolean, Column, String

from base import Base


class VmMac(Base):
    """Class representing VM MAC DB record.
    """

    __tablename__ = 'vm_macs'

    address = Column(String(20), primary_key=True)
    bridge = Column(String(20), primary_key=True)
    in_use = Column(Boolean)
