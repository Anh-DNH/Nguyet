///Return struct deserialized from a .json file
///@arg {String} dir directory to the file
///@return {Struct}
function json_load(dir)
{
	var json_str = "";
	var json_file = file_text_open_read(dir);
	
	while !file_text_eof(json_file)
		json_str += file_text_readln(json_file);
	
	file_text_close(json_file);
	
	return json_parse(json_str);
}

///Serialize a struct into .json data and save it
///@arg {String} dir directory to the file
///@arg {Struct} struct (struct to save)
function json_save(dir, struct)
{
	if file_exists(dir)
		{ file_delete(dir); }
	var jsonFile = file_text_open_write(dir);
	file_text_write_string(jsonFile, json_stringify(struct, true));
	file_text_close(jsonFile);
}