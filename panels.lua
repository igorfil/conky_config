require 'cairo'
require 'imlib2'

panel_r = 45 / 255
panel_g = 45 / 255
panel_b = 45 / 255
panel_a = 128 / 255

panel_title_height = 34

font = "open sans"
font_size_title = 21
caption_r = 240 / 255
caption_g = 240 / 255
caption_b = 240 / 255
caption_a = 240 / 255

font_size = 18
font_r = 240 / 255
font_g = 240 / 255
font_b = 240 / 255
font_a = 240 / 255

text_margin = 10
line_spacing = 10

bar_r = 240 / 255
bar_g = 240 / 255
bar_b = 240 / 255
bar_a = 240 / 255
bar_height = font_size * 0.75



Panel = {x0 = 0, y0 = 0, w = 0, h = 0, title = ""}

function Panel:new (o)
      o = o or {}
      setmetatable(o, self)
      self.__index = self
      return o
end

function Panel:draw_background(cr)
        cairo_set_line_width (cr,0)
        
        -- body
        cairo_set_source_rgba (cr, panel_r, panel_g, panel_b, panel_a)
        cairo_rectangle (cr, self.x0, self.y0, self.w, self.h)
        cairo_fill_preserve (cr)
        cairo_stroke (cr)

        -- header
        cairo_set_source_rgba (cr, panel_r, panel_g, panel_b, panel_a * 1.25)
        cairo_rectangle (cr, self.x0, self.y0, self.w, panel_title_height)
        cairo_fill_preserve (cr)
        cairo_stroke (cr)

        -- caption
        cairo_select_font_face (cr, font, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD)
        cairo_set_source_rgba (cr, caption_r, caption_g, caption_b, caption_a)
        cairo_set_font_size (cr, font_size_title)
        cairo_move_to(cr, self.x0 + self.w / 2 - font_size_title * string.len(self.title) / 3 , self.y0 + font_size_title + (panel_title_height  - font_size_title)/3)
        cairo_show_text(cr, self.title) 
        cairo_stroke(cr)
end

function Panel:draw_bar(x, y, width, value)
    cairo_move_to (cr, x, y)
    cairo_set_source_rgba (cr, bar_r, bar_g, bar_b, bar_a);
    cairo_set_line_width (cr, 1);

    cairo_line_to (cr, x + width, y);
    cairo_line_to (cr, x + width, y + bar_height);
    cairo_line_to (cr, x, y + bar_height);
    cairo_line_to (cr, x, y);
    cairo_stroke (cr);

    cairo_rectangle (cr, x, y, width * value / 100, bar_height)
    cairo_fill_preserve (cr)
    cairo_stroke (cr);
end

function Panel:update()
    if self.update_interval ~= nil then
        if self.last_update + self.update_interval < current_time then
            self.last_update = current_time
            self:do_update()
        end
    end
end

function Panel:do_update()
end


SystemPanel = Panel:new()

function SystemPanel:draw(cr)
    self:draw_background(cr)

    local sys = conky_parse("${sysname}") .. " " .. conky_parse("${kernel}") .. " on " .. conky_parse("${machine}")
    
    cairo_select_font_face (cr, font, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_REGULAR)
    cairo_set_source_rgba (cr, font_r, font_g, font_b, font_a)
    cairo_set_font_size (cr, font_size)
    cairo_move_to(cr, self.x0 + self.w / 2 - font_size * string.len(self.title)*1.2, self.y0 + panel_title_height*2)
    cairo_show_text(cr, sys) 
    cairo_stroke(cr)

    local text_y = self.y0 + panel_title_height * 3
    
    local titles = {
        "Uptime", 
        "CPU Freq", 
        "CPU Load", 
        "CPU Temp", 
        "GPU Temp", 
        "RAM usage", 
        "Network",
        "/",
        "home",
        "big"
    }
    local values = {
        {conky_parse("${uptime}")},
        {conky_parse("${freq}") .. "MHz"},
        {conky_parse("${cpu}") .. "%", conky_parse("${cpu}")},
        {conky_parse("${exec sensors | grep 'Core 3' | awk '{print $3}'}")},
        {"+" .. conky_parse("${exec nvidia-settings -q gpucoretemp 2> /dev/null | grep 'gpu:0' | awk '{print $4}'}") .. "0°C"},
        {conky_parse("${memperc}") .. "%", conky_parse("${memperc}")},
        {"down " .. conky_parse("${downspeedf enp0s31f6}") .. " up " .. conky_parse( "${upspeedf enp0s31f6}")},
        {conky_parse("${fs_used_perc /}") .. "%", conky_parse("${fs_used_perc /}")},
        {conky_parse("${fs_used_perc /home}") .. "%", conky_parse("${fs_used_perc /home}")},
        {conky_parse("${fs_used_perc /media/big}") .. "%", conky_parse("${fs_used_perc /media/big}")}
    }

    cairo_set_source_rgba (cr, font_r, font_g, font_b, font_a*0.75)

    for i=1, #titles do
        cairo_move_to(cr, self.x0 + text_margin, text_y + (font_size + line_spacing) * i)
        cairo_show_text(cr, titles[i] .. ":") 
    end


    cairo_set_source_rgba (cr, font_r, font_g, font_b, font_a)
    
    for i=1, #values do
        if values[i][2] then
            Panel:draw_bar (self.x0 + self.w/2, text_y + (font_size + line_spacing) * i - bar_height, 125, tonumber(values[i][2]))
            cairo_move_to(cr, self.x0 + self.w/2 + 135, text_y + (font_size + line_spacing) * i)
            cairo_show_text(cr, values[i][1]) 
        else
            cairo_move_to(cr, self.x0 + self.w/2, text_y + (font_size + line_spacing) * i)
            cairo_show_text(cr, values[i][1]) 
        end
    end

    cairo_stroke(cr)

end


AgendaPanel = Panel:new()

function AgendaPanel:draw(cr)
    self:draw_background(cr)
    
    cairo_select_font_face (cr, "Monospace", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_REGULAR)
    cairo_set_font_size (cr, font_size)
    cairo_set_source_rgba (cr, font_r, font_g, font_b, font_a)

    local text_y = self.y0 + panel_title_height + line_spacing
    
    for i=1, #self.agenda_data do
        cairo_move_to(cr, self.x0 + text_margin, text_y + (font_size + line_spacing) * i)
        cairo_show_text(cr, self.agenda_data[i]) 
    end
end

function AgendaPanel:do_update()
    self.agenda_data = {}

    local today = os.date("%x") .. " "
    local today_plus_Ndays = os.date("%x", current_time + 60*60*24*31)
    local command = "gcalcli agenda " .. today .. today_plus_Ndays .. " --nocolor"

    f = assert (io.popen (command))

    local max_lines = (self.h - panel_title_height) / (font_size + line_spacing) - 2
    local line_max_length = (self.w + text_margin * 2) / (font_size - 6)

    for line_raw in f:lines() do
        local line = line_raw:gsub("%s+", "")
        
        if line ~= nil and line ~= '' then
            if line_raw:len() > line_max_length then
                line_raw = line_raw:sub(0, line_max_length - 2) .. "..."
            end
            self.agenda_data[#self.agenda_data+1] = line_raw:sub(0, line_max_length)
        end

        if #self.agenda_data >= max_lines then break end
    end
    f:close()
end


QuotesPanel = Panel:new()

function QuotesPanel:draw(cr)
    self:draw_background(cr)

    cairo_select_font_face (cr, font, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_REGULAR)
    cairo_set_font_size (cr, font_size)
    cairo_set_source_rgba (cr, font_r, font_g, font_b, font_a)

    local text_y = self.y0 + panel_title_height + line_spacing
    
    for i=1, #self.data do
        cairo_move_to(cr, self.x0 + text_margin, text_y + (font_size + line_spacing) * i)
        cairo_show_text(cr, self.data[i]) 
    end
end

function QuotesPanel:do_update()
    self.data = {}

    lines = {}
    for line in io.lines(self.file) do 
        lines[#lines + 1] = line
    end

    math.randomseed(os.time())
    i = math.random(#lines)

    local max_lines = (self.h - panel_title_height) / (font_size + line_spacing) - 2
    local line_max_length = (self.w + text_margin * 2) / (font_size - 8)

    local line = lines[i]

    if line ~= nil and line ~= '' then
        if line:len() > line_max_length then
            tmp = ""
            for token in line:gmatch("[^%s]+") do
                if tmp:len() + token:len() <= line_max_length then
                    tmp = tmp .. " " .. token
                else
                    self.data[#self.data+1] = tmp
                    tmp = token
                end
            end
            self.data[#self.data+1] = tmp
        else
            self.data[1] = line 
        end
    end
end


WebcamPanel = Panel:new()

function WebcamPanel:draw(cr)
    self:draw_background(cr)

    if self.image ~= nil then 
        imlib_context_set_image(self.image)
        imlib_render_image_on_drawable(self.x0 + text_margin, self.y0 + panel_title_height + (self.h - panel_title_height - self.image_height - text_margin * 2) / 2)
    end

    cairo_select_font_face (cr, font, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_REGULAR)
    cairo_set_font_size (cr, font_size)
    cairo_set_source_rgba (cr, font_r, font_g, font_b, font_a)

    cairo_move_to(cr, self.x0 + text_margin, self.y0 + self.h - text_margin)
    cairo_show_text(cr, self.webcam_location) 
end

function WebcamPanel:do_update()
-- legacy code
    local f = io.popen("python3 /home/igor/programming/home-projects/conky/webcam.py")

    out =  f:read("*a")
    f:close()

    self.webcam_location = string.sub(out, 0, -2)

    if self.image ~= nil then
        imlib_context_set_image(self.image)
        imlib_free_image()
    end

    if webcam_buffer ~= nil then
        imlib_context_set_image(self.image)
        imlib_free_image()
    end

    webcam_buffer = imlib_load_image("/tmp/webcam.jpg")

    if webcam_buffer == nil then return end

    imlib_context_set_image(webcam_buffer)

    w_img, h_img = imlib_image_get_width(), imlib_image_get_height()

    webcam_max_height = self.h - panel_title_height * 2 - text_margin * 2 
    webcam_max_width = self.w - text_margin * 2

    aspect = w_img / h_img

    self.image_width = webcam_max_width
    self.image_height = self.image_width / aspect

    self.image = imlib_create_image(self.image_width, self.image_height)
    imlib_context_set_image(self.image)

    imlib_blend_image_onto_image(webcam_buffer, 0, 0, 0, w_img, h_img, 0, 0, self.image_width, self.image_height)

    imlib_context_set_image(webcam_buffer)
    imlib_free_image()
    webcam_buffer = nil
end


panels = {
    SystemPanel:new{x0=10, y0=10, w=400, h=400, title="System"},
    AgendaPanel:new{x0=10, y0=500, w=600, h=400, title="Agenda", last_update = 0, update_interval = 60*15, agenda_data = {}},
    QuotesPanel:new{x0=1945, y0=625, w=600, h=300, title="Quotes and Ideas", last_update = 0, update_interval = 60, data = {}, file="/home/igor/Dropbox/ideas/quotes.txt"},
    WebcamPanel:new{x0=1945, y0=10, w=600, h=600, title="Webcam", last_update = 0, update_interval = 60*3, image=nil}
}

function conky_main()
    if conky_window == nil then
        return
    end

    desk = tonumber( conky_parse("${desktop}") )
    if desk == 2 then

        local cs = cairo_xlib_surface_create(conky_window.display,
                                             conky_window.drawable,
                                             conky_window.visual,
                                             conky_window.width,
                                             conky_window.height)
        cr = cairo_create(cs)
        local updates=tonumber(conky_parse('${updates}'))

        if updates>5 then
            current_time = tonumber( conky_parse("${time %s}") )

            for i = 1, #panels do
                panels[i]:update()
                panels[i]:draw(cr)
            end

        end

        cairo_destroy(cr)
        cairo_surface_destroy(cs)
        cr=nil
    end
end
