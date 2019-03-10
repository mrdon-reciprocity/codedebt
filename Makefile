.PHONY: clean, dist
clean:
	rm all.lua

dist:
	luapak merge keys.lua states/* > all.lua
	cat code.lua >> all.lua
	@echo
	@echo When the app starts, press ctrl-s to save, then exit.
	@echo
	/bin/sleep 5
	tic80 codedebt.tic -code all.lua -skip
	


