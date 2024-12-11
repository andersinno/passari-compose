.PHONY: requirements

requirements: requirements.txt

%.txt: %.in
	./compile-requirements $<
