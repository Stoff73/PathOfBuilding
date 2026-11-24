-- Path of Building
--
-- The test card that host_check.lua draws: one of each kind of drawing call, to be checked by eye.
-- Loaded by host_check.lua.
--
local image = ...

return function()
	-- Drawing coordinates are in pixels divided by the display's scale, as Launch.lua's GetVirtualScreenSize has it.
	local w, h = GetScreenSize()
	w, h = w / GetScreenScale(), h / GetScreenScale()
	SetViewport()
	SetDrawLayer(0)
	SetDrawColor(0.2, 0.2, 0.2)
	DrawImage(nil, 0, 0, w, h)
	SetDrawColor(1, 0, 0)
	DrawImage(nil, 20, 20, 100, 100)
	SetDrawColor("^x00FF00")
	DrawImageQuad(nil, 140, 20, 240, 40, 220, 120, 160, 100)
	SetDrawColor(1, 1, 1)
	DrawImage(image, 260, 20, 100, 100)
	DrawImage(image, 380, 20, 100, 100, 0, 0, 0.5, 0.5)
	DrawImageQuad(image, 500, 20, 600, 20, 600, 120, 500, 120, 0, 0, 1, 0, 1, 1, 0, 1)
	SetViewport(20, 140, 200, 30)
	DrawString(0, 0, "LEFT", 24, "VAR", "^7Clipped by the viewport: this sentence runs past its right edge")
	SetViewport()
	SetDrawLayer(5, 1)
	DrawString(20, 190, "LEFT", 16, "FIXED", "^7FIXED 16  ^1red ^2green ^3blue ^4yellow")
	DrawString(0, 220, "CENTER", 32, "VAR BOLD", "^7Centred, bold, 32")
	DrawString(20, 270, "RIGHT", 20, "FONTIN SC", "^7Right aligned")
	DrawString(20, h - 30, "LEFT", 20, "VAR", "^7Bottom left: text below the midpoint must show")
end
