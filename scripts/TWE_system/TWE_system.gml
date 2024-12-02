#region TWE Introduction
/*

						-----TWE: Text With Effect-----

A system that similar to Juju Adams' Scribble text system, but easier to modify.
This system has a lot of limitation and lack of features, so feel free to expand it.

The system use "Command" to do some amazing stuff.
This is how a command looks like:
		
		- Runtime-type command (Command will be executed during text drawing)
		
				<command_name[range](argument1, argument2, ... )>
		
		
		-Convert-type command (Command will be executed during text convering)
		
				{command_name(argument1, argument2, ... )}
		

 -	command_name :	Name of the command you want to use.
 -	range:	How much letter - start from command - will be effected
			(Doesn't work with convert-type command)
 -	argument1, argument2, ... :	Arguments to adjust thing. Some command
									requires a decent of arguments to work
									properly. Others aren't, like the example below.


								* Example *
> In CREATE event--------------------------------------------
var str =	"Test color changing command: " +
			"<rgb[3](255, 0, 0)>RED " +
			"<rgb[5](0, 255, 0)>GREEN " +
			"<rgb[4](0, 0, 255)>BLUE " +
			"<rainbow[7]()>RAINBOW"
			;
text = new TWE_system(x, y, str);

> In DRAW event----------------------------------------------
text.draw();

*/

#endregion

#region TWE System (Constructor)

/**
 *	A system that allows you to create and display a line of beautiful text.
 *	@arg {Real} x
 *	@arg {Real} y
 *	@arg {String} str
 *	@arg {Real} text_index
 *	@arg {Id.Instance OR Struct} companion
**/
function TWE_system(x, y, str, text_index = infinity, companion = noone)
constructor
{
	#region Attributes
	
	Companion = companion;
	
	X = x;
	Y = y;
	W = 0;
	H = 0;
	
	DisplayTxt = "";
	Command = [];
	CmdAddr = [];
	TextAmount = max(text_index, 0);
	LoopTick = 0;
	
	Letter = TWE_letter_attributes();
		
	StopExec = false;
	
	#endregion
	
	#region Methods
	
	function convert(RawTxt)
	{
		DisplayTxt = "";
		
		//Clear leftover commands
		array_foreach(Command, function(e) { delete e; });
		Command = [];
		CmdAddr = [];
		
		//Setup for string convert
		var getCmd = false;
		var cmdName = "";
		
		var getCmdArg = false;
		var cmdArg = [];

		var getCmdTime = false;
		var cmdTime = "0";
		
		var execCmd = false;

		for (var i = 1; i <= string_length(RawTxt); i++)
		{
			var letter = string_char_at(RawTxt, i);
			var nextletter = string_char_at(RawTxt, i + 1);
			
			if (letter == "<")
			{
				i++;	//Skip letter so command name won't have "<" in it
		
				if (nextletter != "<")	//Start scanning to create a command
				{
					getCmd = !execCmd;
					cmdName = "";
					
					//Set cmdTime here so that the range will always be reset
					//to 0 when a command is being detected.
					cmdTime = "0";
					
					//Recording Address
					array_push(CmdAddr, string_length(DisplayTxt) + 1);
					
					//Get to the next letter
					letter = string_char_at(RawTxt, i);
					nextletter = string_char_at(RawTxt, i + 1);
				}
				//	else if the system detect "<<" it will not
				//	create a new command and add "<" into DisplayTxt
			}
			
			if (letter == "{")
			{
				i++;	//Skip letter so command's name won't have "{" in it
		
				if (nextletter != "{")	//Create a command and start modifying it
				{
					execCmd = !getCmd;
					cmdName = "";
					
					//Get to the next letter
					letter = string_char_at(RawTxt, i);
					nextletter = string_char_at(RawTxt, i + 1);
				}
				//	else if the system detect "{{" it will not
				//	create a new command and add "{" into DisplayTxt
			}
			
			if getCmd or execCmd	//Scan command
			{
				#region Start scanning
		
				if (letter = "[")
				{
					getCmdTime = true;
					i++;	//Skip letter so range number won't have "[" in it
					letter = string_char_at(RawTxt, i);
				}
			
					if (letter = "(")
					{
						getCmdArg = true;
						cmdArg = [self, ""];
						i++;	//Skip letter so first argument won't have "(" in it
						letter = string_char_at(RawTxt, i);
					}
			
				#endregion
			
				#region Scanning and Processing
		
					//Scan Effect range
					if getCmdTime
						{ cmdTime += letter != "]" ? letter : ""; }
					
					//Scan Arguments
					if getCmdArg
					{
						if (letter == ",")	//Seperate argument
							{ array_push(cmdArg, ""); }
						else if (letter != ")")// and (letter != " ")
						//Prevent having ")" inside last argument
							{ cmdArg[array_length(cmdArg) - 1] += letter; }
					}
					
					//Scan Name
					if !getCmdTime
					and !getCmdArg
					and (letter != ">")	//Prevent having ">" inside command's name
					and (letter != "}")	//Prevent having "}" inside command's name
						{ cmdName += letter; }
			
				#endregion
		
				#region Stop scanning
		
					if (letter = "]")
						{ getCmdTime = false; }
			
				if (letter = ")")
					{ getCmdArg = false; }
					
			if (letter == ">") and getCmd
			{
				if !script_exists(asset_get_index("TWE_cmd_" + cmdName))
				{
					show_error(
						"TWE ERROR: Command \"" + cmdName + "\" does not exists!\n" +
						"Recommend you re-check this line of string:" +
						"\n\n\n\"" + RawTxt + "\"\n\n",
						false
					);
				}
				else
				{
					array_push(Command, {
						Func : asset_get_index("TWE_cmd_" + cmdName),
						Arg : cmdArg,
						EndAt : string_length(DisplayTxt) + real(cmdTime)
					});
					getCmd = false;
				}
			}
			
			if (letter == "}") and execCmd
			{
				if !script_exists(asset_get_index("TWE_cmd_" + cmdName))
				{
					show_error(
						"TWE ERROR: Cannot execute command \"" + cmdName + "\"" +
						"Recommend you re-check this line of string: " +
						"\n\n\n\"" + RawTxt + "\"\n\n",
						false
					);
				}
				else
				{
					script_execute_ext(asset_get_index("TWE_cmd_" + cmdName), cmdArg);
					execCmd = false;
				}
			}
		
				#endregion
			}
			else
			{
				if (letter == "\n")
				{
					var this = self;
					array_push(CmdAddr, string_length(DisplayTxt) + 1);
					array_push(Command, {
						Func : TWE_cmd_nextline,
						Arg : [this], //so that Arg[] will store the address of the TWE system, not the command struct
						EndAt : string_length(DisplayTxt) + 1
					});
				}
				else if (letter == "\t")
				{
					DisplayTxt += "      ";
					i++;
					letter = string_char_at(RawTxt, i);
					nextletter = string_char_at(RawTxt, i + 1);
				}
				//else if (letter == ",")
				//and TWE_is_textbubble(self)
				//{
				//	var this = self;
				//	array_push(CmdAddr, string_length(DisplayTxt) + 1);
				//	array_push(Command, {
				//		Func : TWE_cmd_wait,
				//		Arg : [this, 0.2], //so that Arg[] will store the address of the TWE system, not the command struct
				//		EndAt : string_length(DisplayTxt) + 1
				//	});
				//}
				//else if (letter == ".")
				//and TWE_is_textbubble(self)
				//{
				//	var this = self;
				//	array_push(CmdAddr, string_length(DisplayTxt) + 1);
				//	array_push(Command, {
				//		Func : TWE_cmd_wait,
				//		Arg : [this, 0.9], //so that Arg[] will store the address of the TWE system, not the command struct
				//		EndAt : string_length(DisplayTxt) + 1
				//	});
				//}
				
				DisplayTxt += letter;
			}
		}
		
		//Get text's width/height
		draw_set_font(Letter.Font);
		W = string_width(DisplayTxt);
		H = string_height(DisplayTxt);
		draw_set_font(noone);
	}
	
	function draw()
	{
		Letter.X = 0;
		Letter.Y = 0;
		
		var EXECUTE_COMMAND = [];
		var LoopMax = min(string_length(DisplayTxt) + 8, TextAmount);
		var CmdAddrPter = 0;
		for (LoopTick = 1; LoopTick <= LoopMax; LoopTick++)
		{
			#region Before Draw Letter
			
				draw_set_color(Letter.Color);
				draw_set_font(Letter.Font);
				Letter.Char = LoopTick <= string_length(DisplayTxt) ? string_char_at(DisplayTxt, LoopTick) : "";
				Letter.Xoffset = 0;
				Letter.Yoffset = 0;
				Letter.Xscale = 1;
				Letter.Yscale = 1;
				
				//Add command to EXECUTE_COMMAND
				while (CmdAddrPter < array_length(CmdAddr))
				and (CmdAddr[CmdAddrPter] == LoopTick)
				{					
					//Add command to queue
					array_push(EXECUTE_COMMAND, Command[CmdAddrPter]);
					
					//Push TextAmount if it's smaller than LoopTick
					if ( floor(TextAmount) < LoopTick )
						{ TextAmount = LoopTick; }
					
					CmdAddrPter++;
				}
				
				//Execute & Remove commands
				for (var v = 0; v < array_length(EXECUTE_COMMAND); v++)
				{
					script_execute_ext(
						EXECUTE_COMMAND[v].Func,
						EXECUTE_COMMAND[v].Arg
					);
					if (LoopTick >= EXECUTE_COMMAND[v].EndAt)
						{ array_delete(EXECUTE_COMMAND, v, 1); v--; }
					if StopExec
						{ StopExec = false; break; }
				}
				
			#endregion
			
			#region Draw Letter
			
				draw_text_transformed(
					X + Letter.X + Letter.Xoffset,
					Y + Letter.Y + Letter.Yoffset,
					Letter.Char,
					Letter.Xscale,
					Letter.Yscale, 
					Letter.Angle
				);
			
			#endregion
			
			#region After Draw Letter
			
				Letter.X += string_width(Letter.Char) * Letter.Xscale;
			
				//if (Letter.Char == " ") and (Letter.X >= W)
					//{ Letter.X = 0; Letter.Y += string_height("|"); }
			
			#endregion
		}
		
		draw_set_color(c_white);
		draw_set_font(noone);
		
	}
	
	#endregion
	convert(str);
	
	toString = function()
		{ return "TWE"; }
}

function TWE_letter_attributes()
{
	return {
		Char : "",
		X : 0,				Y : 0,
		W : 0,				H : 0,
		Xoffset : 0,		Yoffset : 0,
		Xscale : 1,		Yscale : 1,
		
		Angle : 0,
		Color : c_white,
		Font : fnt_main
	}
}

#endregion

#region TWE Functions (Common)

///Literally crash the whole game by a single dialogue line
function TWE_cmd_crash(TWE)
	{ game_end(); }

///This is a TWE function for command <debug_msg(str)>,
///don't use it outside the TWE system
///@deprecated
function TWE_cmd_debug_msg(TWE, str)
{
	if (TWE.LoopTick == TWE.TextAmount)
		{ show_debug_message(str); }
}

///This is a TWE function for command <shake()>,
///don't use it outside the TWE system
///@deprecated
function TWE_cmd_shake(TWE, w, h)
{
	TWE.Letter.Xoffset += random_range(-real(w) / 2, real(w) / 2);
	TWE.Letter.Yoffset += random_range(-real(h) / 2, real(h) / 2);
}

///This is a TWE function for command <wave()>,
///don't use it outside the TWE system
///@deprecated
function TWE_cmd_wave(TWE, w, h, weight = 0.3)
{
	var timer = get_timer() / 400_000;
	TWE.Letter.Xoffset += sin(timer + (TWE.LoopTick * weight)) * real(w);
	TWE.Letter.Yoffset += cos(timer + (TWE.LoopTick * weight)) * real(h);
}

///This is a TWE function for command <rainbow1[n]()>,
///don't use it outside the TWE system
///@deprecated
function TWE_cmd_rainbow1(TWE)
{
	var col = make_color_hsv
		(wrap((get_timer() / 10000), 0, 255), 150, 255);
	draw_set_color(col);
}

///This is a TWE function for command <rainbow2[n]()>,
///don't use it outside the TWE system
///@deprecated
function TWE_cmd_rainbow2(TWE)
{
	var col = make_color_hsv
		(wrap((get_timer() / 10000) + (TWE.LoopTick * 32), 0, 255), 150, 255);
	draw_set_color(col);
}

///This is a TWE function for command <sound(name)>,
///don't use it outside the TWE system
///@deprecated
function TWE_cmd_sound(TWE, sound)
{
	if (TWE.LoopTick == TWE.TextAmount)
		{ audio_play_sound(asset_get_index(sound), 1000, false); }
}

///This is a TWE function for command <nextline()>,
///don't use it outside the TWE system
///@deprecated
function TWE_cmd_nextline(TWE)
{
	TWE.Letter.X = 0;
	TWE.Letter.Y += string_height("|");
}

///This is a TWE function for command <font[n](name)>,
///don't use it outside the TWE system
///@deprecated
function TWE_cmd_font(TWE, font)
	{ draw_set_font(asset_get_index(font)); }

///This is a TWE function for command <hsv[n](hue, sat, val)>,
///don't use it outside the TWE system
///@deprecated
function TWE_cmd_hsv(TWE, hue, sat, val)
	{ draw_set_color(make_color_hsv(real(hue), real(sat), real(val))); }

///This is a TWE function for command <rgb[n](red, green, blue)>,
///don't use it outside the TWE system
///@deprecated
function TWE_cmd_rgb(TWE, red, green, blue)
	{ draw_set_color(make_color_rgb(real(red), real(green), real(blue))); }

///This is a TWE function for command <scale[n](xscale, yscale)>,
///don't use it outside the TWE system
///@deprecated
function TWE_cmd_scale(TWE, xscale, yscale)
{
	TWE.Letter.Xscale = real(xscale);
	TWE.Letter.Yscale = real(yscale);
}

///This is a TWE function for command {weekday}	(Convert command),
///don't use it outside the TWE system
///@deprecated
function TWE_cmd_weekday(TWE)
{
	var dtime = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
	TWE.DisplayTxt += dtime[current_weekday];
}

///This is a TWE function for command {day} (Convert command),
///don't use it outside the TWE system
///@deprecated
function TWE_cmd_day(TWE)
{
	TWE.DisplayTxt += string(current_day);
}

///This is a TWE function for command {month}	(Convert command),
///don't use it outside the TWE system
///@deprecated
function TWE_cmd_month(TWE)
{
	var months = [
		"January", "Febuary", "March",
		"April", "May", "June",
		"July", "August", "September",
		"October", "November", "December"
	];
	TWE.DisplayTxt += months[current_month - 1];
}

///This is a TWE function for command {year} (Convert command),
///don't use it outside the TWE system
///@deprecated
function TWE_cmd_year(TWE)
{
	TWE.DisplayTxt += string(current_year);
}

function TWE_cmd_hour(TWE)
{
	var str = string(current_hour);
	str = current_hour < 10 ? "0" + str : str;
	draw_text_transformed(
		X + Letter.X + Letter.Xoffset,
		Y + Letter.Y + Letter.Yoffset,
		str,
		Letter.Xscale,
		Letter.Yscale, 
		Letter.Angle
	);
	Letter.X += string_width(str) * Letter.Xscale;
}

function TWE_cmd_minute(TWE)
{
	var str = string(current_minute);
	str = current_minute < 10 ? "0" + str : str;
	draw_text_transformed(
		X + Letter.X + Letter.Xoffset,
		Y + Letter.Y + Letter.Yoffset,
		str,
		Letter.Xscale,
		Letter.Yscale, 
		Letter.Angle
	);
	Letter.X += string_width(str) * Letter.Xscale;
}

function TWE_cmd_second(TWE)
{
	var str = string(current_second);
	str = current_second < 10 ? "0" + str : str;
	draw_text_transformed(
		X + Letter.X + Letter.Xoffset,
		Y + Letter.Y + Letter.Yoffset,
		str,
		Letter.Xscale,
		Letter.Yscale, 
		Letter.Angle
	);
	Letter.X += string_width(str) * Letter.Xscale;
}

#endregion

#region TWE Functions (with companion)

function TWE_in_textbubble(TWE)
{
	return instance_exists(TWE.Companion)
	and (TWE.Companion.object_index == obj_textbubble)
}

///This is a TWE function for command <wait(second)>,
///don't use it outside the TWE system
///@deprecated
function TWE_cmd_wait(TWE, time)
{
	if !(TWE_in_textbubble(TWE))
	or (TWE.LoopTick != TWE.TextAmount)
		{ return; }
	
	//show_debug_message($"{argument[0]}, {argument[1]}, {argument[2]}");
	if (TWE.Companion.WaitTime == -1)
		{ TWE.Companion.WaitTime = real(time) * game_get_speed(gamespeed_fps); }
	TWE.Letter.Char = "";
	TWE.LoopTick = infinity;	//end the loop
}

///This is a TWE function for command <waitinput>,
///don't use it outside the TWE system
///@deprecated
function TWE_cmd_waitinput(TWE)
{
	if !(TWE_in_textbubble(TWE))
	or (TWE.LoopTick != TWE.TextAmount)
		{ return; }
	
	var inputAccept = input("accept") or mouse_check_button_pressed(mb_left);
	TWE.Companion.WaitTime = !inputAccept * 2;
	TWE.Letter.Char = "";
	TWE.LoopTick = infinity;
}

///This is a TWE function for command <skipchar(number_of_char)>,
///don't use it outside the TWE system
///@deprecated
function TWE_cmd_skipchar(TWE, number_of_char)
{
	if TWE_in_textbubble(TWE)
	and (TWE.LoopTick == TWE.TextAmount)
	{
		while (TWE.TextAmount < TWE.LoopTick + number_of_char - 1)
			{ TWE.TextAmount += TWE.Companion.TextSpd; }
		TWE.Letter.Char = "";
		TWE.LoopTick = infinity;
	}
}

///This is a TWE function for command <voice(name)>,
///don't use it outside the TWE system
///@deprecated
function TWE_cmd_voice(TWE, sound)
{
	if TWE_in_textbubble(TWE) and (TWE.LoopTick == TWE.TextAmount)
	{
		TWE.Companion.Voice = global.CharaVoice[$ sound];
		TWE.Companion.VoTick = infinity;
	}
}

///This is a TWE function for command <speed(spd)>,
///don't use it outside the TWE system
///@deprecated
function TWE_cmd_speed(TWE, spd)
{
	if TWE_in_textbubble(TWE)
		{ TWE.Companion.TextSpd = real(spd); }
}

///This is a TWE function for command <unskip(name)>,
///don't use it outside the TWE system
///@deprecated
function TWE_cmd_unskip(TWE, unskip)
{
	if TWE_in_textbubble(TWE)
		{ TWE.Companion.UnSkip = (unskip == "true"); }
}

///This is a TWE function for command <randomline[n](n1, n2, n3...)>,
///don't use it outside the TWE system
///@deprecated
function TWE_cmd_randomline(TWE)
{
	var n = real(argument[irandom_range(1, argument_count - 1)])
	if TWE_in_textbubble(TWE)
	{
		TWE.Companion.Line = n;
		TWE.convert(TWE.Companion.RawText[n]);
		TWE.TextAmount = 0;
	}
}

///This is a TWE function for command <enddiag>,
///don't use it outside the TWE system
///@deprecated
function TWE_cmd_enddiag(TWE)
{
	if TWE_in_textbubble(TWE)
		{ TWE.Companion.EndDiag = true; }
}

///This is a TWE function for command <line(n)>,
///don't use it outside the TWE system
///@deprecated
function TWE_cmd_line(TWE, n)
{
	if TWE_in_textbubble(TWE)
	{
		TWE.Companion.Line = real(n);
		TWE.convert(TWE.Companion.RawText[real(n)]);
		TWE.TextAmount = 0;
	}
}

//This is a TWE function for command <bubble_autosize[n]()>,
//don't use it outside the TWE system
//@deprecated
function TWE_cmd_bubble_size_update(TWE)
{
	if TWE_in_textbubble(TWE)
	{
		TWE.Companion.w = TWE.W + TWE.Companion.BorderW;
		TWE.Companion.h = TWE.H + TWE.Companion.BorderH;
	}
}

///This is a TWE function for command <diagtab()>,
///don't use it outside the TWE system
///@deprecated
function TWE_cmd_diagtab(TWE)
{
	if TWE_in_textbubble(TWE)
		{ TWE.Letter.X += string_length("  "); }
}

///This is a TWE function for command <holder(spr_holder)>,
///don't use it outside the TWE system
///@deprecated
function TWE_cmd_holder(TWE, spr_holder)
{
	if !(TWE_in_textbubble(TWE))
		{ return; }
	
	spr_holder = asset_get_index(spr_holder);
	if sprite_exists(spr_holder)
	and (sprite_get_texture(TWE.Companion.Holder, 0) != sprite_get_texture(spr_holder, 0))
		{ sprite_assign(TWE.Companion.Holder, spr_holder); }
}

///This is a TWE function for command <player_moveable(spr_holder)>,
///don't use it outside the TWE system
///@deprecated
function TWE_cmd_player_moveable(TWE, movable)
{
	if instance_exists(PLAYER)
		{ PLAYER.moveable = bool(movable); }
}

///This is a TWE function for command <player_interactable(spr_holder)>,
///don't use it outside the TWE system
///@deprecated
function TWE_cmd_player_interactable(TWE, interactable)
{
	if instance_exists(PLAYER)
		{ PLAYER.interactable = bool(interactable); }
}

///This is a TWE function for command <option(spr_holder)>,
///don't use it outside the TWE system
///@deprecated
function TWE_cmd_option()
{
	var TWE = argument[0];
	if !(TWE_in_textbubble(TWE))
	//or (TWE.LoopTick != TWE.TextAmount)
	or (TWE.Companion.Option != undefined)
		{ return; }
	
	var option = [];
	for (var i = 1; i < argument_count; i++)
		{ option[i - 1] = argument[i]; }
	
	var optSys = new option_sprite_cursor(option);
	with optSys
	{
		Halign = fa_right;
		TxtCol = c_blue;
		font(fnt_main);
		cursor(spr_textbubble_csor);
		update_option();
		SpaceW += 2;
	}
	TWE.Companion.Option = optSys;
	TWE.Companion.OptionDraw = true;
}

//function TWE_in_textbox(TWE)
//{
//	var str = instanceof(TWE.Companion);
//	return str == "textbox"
//	or str == "textbox_battle";
//}

//function TWE_cmd_inputskip(TWE, number_of_char)
//{
//	if TWE_in_textbox(TWE) and (TWE.LoopTick == TWE.TextAmount)
//		{ TWE.Companion.Skipper = number_of_char; }
//}

//This is a TWE function for command <bubble_size[n](w, h)>,
//don't use it outside the TWE system
//@deprecated
//function TWE_cmd_bubble_size(TWE, w, h)
//{
//	if TWE_in_textbox(TWE)
//		{ TWE.Companion.w = real(w); TWE.Companion.h = real(h); }
//}

///This is a TWE function for command <portrait(sprite)>,
///don't use it outside the TWE system
///@deprecated
//function TWE_cmd_portrait(TWE, sprite)
//{
//	if (TWE.LoopTick == TWE.TextAmount)
//	and TWE_in_textbox(TWE)
//		{ TWE.Companion.Portrait = asset_get_index(sprite); }
//}

///This is a TWE function for command <progress(num)>,
///don't use it outside the TWE system
///@deprecated
//function TWE_cmd_progress(TWE, num)
//{
//	if TWE_in_textbox(TWE)
//	and (num > TWE.Companion.Progress)
//		{ TWE.Companion.Progress = num; }
//}

///This is a TWE function for command <progress_reset()>,
///don't use it outside the TWE system
///@deprecated
//function TWE_cmd_progress_reset(TWE)
//{
//	if TWE_in_textbox(TWE)
//		{ TWE.Companion.Progress = -1; }
//}


///This is a TWE function for command <dnl()>,
///don't use it outside the TWE system
///@deprecated
//dnl: dialogue next line
//function TWE_cmd_dnl(TWE)
//{
//	TWE.Letter.X = string_width("* ");
//	if (instanceof(TWE.Companion) == "textbox")
//		{ TWE.Letter.Y += string_height("|") + 5; }
//	else if (instanceof(TWE.Companion) == "textbox_battle")
//		{ TWE.Letter.Y += string_height("|") + 3; }
//}

///This is a TWE function for command <dnl()>,
///don't use it outside the TWE system
///@deprecated
//function TWE_cmd_mononl(TWE)
//{
//	TWE.Letter.X = 0;
//	if (instanceof(TWE.Companion) == "textbox")
//		{ TWE.Letter.Y += string_height("|") + 5; }
//	else if (instanceof(TWE.Companion) == "textbox_battle")
//		{ TWE.Letter.Y += string_height("|") + 3; }
//}

#endregion
