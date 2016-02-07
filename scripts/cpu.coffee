class Cpu
	constructor: (bios) ->
		@inscount = 0 # Number of instructions executed
		@mem = new Memory @, bios
		@regs = [
			0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0
		]
		@hi = @lo = @pc = @asid = 0
		@delay = null # Delay slot for execution

		@cop0reg = [
			0, 0, 0, 0, 0, 0, 0, 0, 
			0, 0, 0, 0, 0, 0, 0, 0, 
			0, 0, 0, 0, 0, 0, 0, 0, 
			0, 0, 0, 0, 0, 0, 0, 0
		]

	execute_one: (pc) ->
		@inscount++
		interpret pc, @mem.uint32(pc), @

	branch: (pc) ->
		@delay = @pc + 4
		@pc = pc - 4 # Compensate for PC push

	run: (count=1000000) ->
		for i in [0...count]
			delayed = @delay != null
			cpc = if delayed then @delay else @pc
			@delay = null
			try
				if @execute_one(cpc) == false
					inst = @mem.uint32 cpc
					phex32 cpc, inst, disassemble(cpc, inst)
					throw 'Unknown instruction'
			catch e
				return e
			
			@pc += 4 if not delayed
		true

	copreg: (cop, reg, val=null) ->
		if cop == 0
			if val == null
				@cop0reg[reg]
			else
				@cop0reg[reg] = val
				if reg == COP0_SR
					@mem.isolate = ((val >>> 16) & 1) == 1 # Isolate Cache
		else
			console.log 'Unknown copreg access', cop, reg, val
			throw 'Fail'

	copfun: (cop, cofun) ->
		if cop == 0
			switch cofun
				when 16 # RFE
					sr = @cop0reg[COP0_SR]
					bottom = (sr >>> 2) & 0xF
					top = sr >>> 4
					@cop0reg[COP0_SR] = (bottom | top) >>> 0
				else
					console.log 'Unknown cop0 function:', cofun
					throw 'Fail'
		else
			console.log 'Unknown cop' + cop, 'function', cofun
			throw 'Fail'

