FIND ?= find
PYLINT ?= pylint3

pylint:
	$(FIND) . -type f -a -name '*.py' -print0 | xargs -0 $(PYLINT) --rcfile=./pylint.rc
