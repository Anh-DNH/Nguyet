draw_set_font(fnt_main);

function mouse_in_rectangle(x1, y1, x2, y2, w, h)
{
	x2 = w == undefined ? x2 : x1 + w;
	y2 = h == undefined ? y2 : y1 + h;
	return point_in_rectangle(mouse_x, mouse_y, x1, y1, x2, y2);
}


//function gui_to_room_x(_x)
//{
//	var scale = camera_get_view_width(view_camera[0]) / display_get_gui_width();
//	return camera_get_view_x(view_camera[0]) + _x * scale;
//}

//function gui_to_room_y(_y)
//{
//	var scale = camera_get_view_height(view_camera[0]) / display_get_gui_height();
//	return camera_get_view_y(view_camera[0]) + _y * scale;
//}


function draw_set_align(halign, valign)
{
	draw_set_halign(halign);
	draw_set_valign(valign);
}