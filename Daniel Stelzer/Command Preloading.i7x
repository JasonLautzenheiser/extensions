Command Preloading (for Glulx only) by Daniel Stelzer begins here.

"A simple way to preload input onto the command line before the player begins to type."

"based on I6 code by Andrew Plotkin"

The preloaded input buffer is initially "".
To empty the preloaded input buffer (this is preload-reset): now the preloaded input buffer is "".
To preload the command (T - text): now the preloaded input buffer is T.

Include (-

[ VM_KeyChar win nostat done res ix jx ch;
	jx = ch; ! squash compiler warnings
	if (win == 0) win = gg_mainwin;
	if (gg_commandstr ~= 0 && gg_command_reading ~= false) {
		done = glk_get_line_stream(gg_commandstr, gg_arguments, 31);
		if (done == 0) {
			glk_stream_close(gg_commandstr, 0);
			gg_commandstr = 0;
			gg_command_reading = false;
			! fall through to normal user input.
		} else {
			! Trim the trailing newline
			if (gg_arguments->(done-1) == 10) done = done-1;
			res = gg_arguments->0;
			if (res == '\') {
				res = 0;
				for (ix=1 : ix<done : ix++) {
					ch = gg_arguments->ix;
					if (ch >= '0' && ch <= '9') {
						@shiftl res 4 res;
						res = res + (ch-'0');
					} else if (ch >= 'a' && ch <= 'f') {
						@shiftl res 4 res;
						res = res + (ch+10-'a');
					} else if (ch >= 'A' && ch <= 'F') {
						@shiftl res 4 res;
						res = res + (ch+10-'A');
					}
				}
			}
	   		jump KCPContinue;
		}
	}
	done = false;
	glk_request_char_event(win);
	while (~~done) {
		glk_select(gg_event);
		switch (gg_event-->0) {
		  5: ! evtype_Arrange
			if (nostat) {
				glk_cancel_char_event(win);
				res = $80000000;
				done = true;
				break;
			}
			DrawStatusLine();
		  2: ! evtype_CharInput
			if (gg_event-->1 == win) {
				res = gg_event-->2;
				done = true;
				}
		}
		ix = HandleGlkEvent(gg_event, 1, gg_arguments);
		if (ix == 2) {
			res = gg_arguments-->0;
			done = true;
		} else if (ix == -1)  done = false;
	}
	if (gg_commandstr ~= 0 && gg_command_reading == false) {
		if (res < 32 || res >= 256 || (res == '\' or ' ')) {
			glk_put_char_stream(gg_commandstr, '\');
			done = 0;
			jx = res;
			for (ix=0 : ix<8 : ix++) {
				@ushiftr jx 28 ch;
				@shiftl jx 4 jx;
				ch = ch & $0F;
				if (ch ~= 0 || ix == 7) done = 1;
				if (done) {
					if (ch >= 0 && ch <= 9) ch = ch + '0';
					else                    ch = (ch - 10) + 'A';
					glk_put_char_stream(gg_commandstr, ch);
				}
			}
		} else {
			glk_put_char_stream(gg_commandstr, res);
		}
		glk_put_char_stream(gg_commandstr, 10); ! newline
	}
  .KCPContinue;
	return res;
];

[ VM_KeyDelay tenths  key done ix;
	glk_request_char_event(gg_mainwin);
	glk_request_timer_events(tenths*100);
	while (~~done) {
		glk_select(gg_event);
		ix = HandleGlkEvent(gg_event, 1, gg_arguments);
		if (ix == 2) {
			key = gg_arguments-->0;
			done = true;
		}
		else if (ix >= 0 && gg_event-->0 == 1 or 2) {
			key = gg_event-->2;
			done = true;
		}
	}
	glk_cancel_char_event(gg_mainwin);
	glk_request_timer_events(0);
	return key;
];

[ VM_ReadKeyboard  a_buffer a_table done ix;
	if (gg_commandstr ~= 0 && gg_command_reading ~= false) {
		done = glk_get_line_stream(gg_commandstr, a_buffer+WORDSIZE,
			(INPUT_BUFFER_LEN-WORDSIZE)-1);
		if (done == 0) {
			glk_stream_close(gg_commandstr, 0);
			gg_commandstr = 0;
			gg_command_reading = false;
		}
		else {
			! Trim the trailing newline
			if ((a_buffer+WORDSIZE)->(done-1) == 10) done = done-1;
			a_buffer-->0 = done;
			VM_Style(INPUT_VMSTY);
			glk_put_buffer(a_buffer+WORDSIZE, done);
			VM_Style(NORMAL_VMSTY);
			print "^";
			jump KPContinue;
		}
	}
	done = false;
	
	VM_PrintToBuffer(a_buffer, INPUT_BUFFER_LEN-WORDSIZE, TEXT_TY_Say, (+ preloaded input buffer +)); !!! CHANGED
	glk_request_line_event(gg_mainwin, a_buffer+WORDSIZE, INPUT_BUFFER_LEN-WORDSIZE, a_buffer-->0); !!! CHANGED
	((+ preload-reset +)-->1)(); !!! CHANGED
	
	while (~~done) {
		glk_select(gg_event);
		switch (gg_event-->0) {
		  5: ! evtype_Arrange
			DrawStatusLine();
		  3: ! evtype_LineInput
			if (gg_event-->1 == gg_mainwin) {
				a_buffer-->0 = gg_event-->2;
				done = true;
			}
		}
		ix = HandleGlkEvent(gg_event, 0, a_buffer);
		if (ix == 2) done = true;
		else if (ix == -1) done = false;
	}
	if (gg_commandstr ~= 0 && gg_command_reading == false) {
		glk_put_buffer_stream(gg_commandstr, a_buffer+WORDSIZE, a_buffer-->0);
		glk_put_char_stream(gg_commandstr, 10); ! newline
	}
  .KPContinue;
	VM_Tokenise(a_buffer,a_table);
	! It's time to close any quote window we've got going.
	if (gg_quotewin) {
		glk_window_close(gg_quotewin, 0);
		gg_quotewin = 0;
	}
	#ifdef ECHO_COMMANDS;
	print "** ";
	for (ix=WORDSIZE: ix<(a_buffer-->0)+WORDSIZE: ix++) print (char) a_buffer->ix;
	print "^";
	#endif; ! ECHO_COMMANDS
];

-) instead of "Keyboard Input" in "Glulx.i6t".

Command Preloading ends here.

---- DOCUMENTATION ----

This provides a simple way to preload the command line, so that there are already some letters there in the buffer when the player starts to type.

	preload the command "take "

This phrase puts "take " into the input buffer as though the player had typed it when their next command begins.
