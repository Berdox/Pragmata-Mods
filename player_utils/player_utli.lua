local enable_script = false
local enable_player_pos = false
local enable_camera_rot = false
local enable_player_invinc = false
local enable_player_gravity = false
local grav_rate = 1.0
local text_pos_x = 0.35 
local text_pos_y = 0.8
local text_cam_x = 0.35 
local text_cam_y = 0.83
local big_font = imgui.load_font(nil, 42)

local function quaternion_to_euler_fixed(q)
    local rad_to_deg = 180 / math.pi

    -- 1. Pitch (The one you want stable)
    -- We use the Forward-Y component specifically
    local sinp = 2 * (q.w * q.x - q.y * q.z)
    local pitch
    if math.abs(sinp) >= 1 then
        pitch = (sinp > 0 and 1 or -1) * (math.pi / 2)
    else
        pitch = math.asin(sinp)
    end

    -- 2. Yaw (Horizontal)
    local siny_cosp = 2 * (q.w * q.y + q.z * q.x)
    local cosy_cosp = 1 - 2 * (q.x * q.x + q.y * q.y)
    local yaw = math.atan(siny_cosp, cosy_cosp)

    -- Convert to degrees and wrap to 360
    local final_yaw = (yaw * rad_to_deg) % 360
    local final_pitch = (pitch * rad_to_deg) % 360

    return final_yaw, final_pitch
end


re.on_draw_ui(function()
    if imgui.tree_node("Player Utils") then
        _, enable_script = imgui.checkbox("Start Player Utils", enable_script)
        
        -- Everything below this line only shows if "Start Player Utils" is checked
        if enable_script then
            imgui.separator() -- Adds a nice visual line to separate the master switch

            if imgui.tree_node("Player Position") then
                _, enable_player_pos = imgui.checkbox("Enable Player Position", enable_player_pos)
                _, text_pos_x = imgui.slider_float("Text X Position", text_pos_x, 0.0, 1.0)
                _, text_pos_y = imgui.slider_float("Text Y Position", text_pos_y, 0.0, 1.0)
                imgui.tree_pop()
            end

            imgui.separator()

            if imgui.tree_node("Player Camera Rotation") then
                _, enable_camera_rot = imgui.checkbox("Enable Player Position", enable_camera_rot)
                _, text_cam_x = imgui.slider_float("Text X Position", text_cam_x, 0.0, 1.0)
                _, text_cam_y = imgui.slider_float("Text Y Position", text_cam_y, 0.0, 1.0)
                imgui.tree_pop()
            end

            imgui.separator()

            if imgui.tree_node("Player Invincibility") then
                _, enable_player_invinc = imgui.checkbox("Enable Player Invincibility", enable_player_invinc)
                imgui.tree_pop()
            end

            imgui.separator()

            if imgui.tree_node("Player Gravity (Not Working)") then
                _, enable_player_gravity = imgui.checkbox("Enable Player Gravity Manipulation", enable_player_gravity)
                _, grav_rate = imgui.slider_float("Gravity Rate", grav_rate, 0.0, 25.0)

                if imgui.button("Reset Gravity") then
                    grav_rate = 1.0
                    local char_man = sdk.get_managed_singleton("app.CharacterManager")
                    if char_man then 
                        char_man:call("resetGravityRate") 
                    end
                end
                imgui.tree_pop()
            end
        end

        imgui.tree_pop()
    end
end)


re.on_frame(function()
    if not enable_script then return end

    local char_man = sdk.get_managed_singleton("app.CharacterManager")
    if not char_man then return end

    local player_handle = char_man:call("getPlayerHandle")
    if not player_handle then return end

    local camera_system = sdk.get_managed_singleton("app.CameraSystem")
    if not camera_system then return end

    local screen_size = imgui.get_display_size()

    if enable_player_pos then
    ---------------------- Player position ----------------------------------
        local player_pos = player_handle:call("get_Position")
        if not player_pos then return end
        
        local pos_text = string.format("Player: X: %.4f, Y: %.4f, Z: %.4f", player_pos.x, player_pos.z, player_pos.y)
            
        -- 2. Calculate coordinates (Percentage * Resolution)
        local draw_x = screen_size.x * text_pos_x
        local draw_y = screen_size.y * text_pos_y

        -- 3. Draw
        imgui.push_font(big_font)
        draw.text(pos_text, draw_x, draw_y, 0xFFFFFFFF)
        imgui.pop_font()

    end

    ---------------------------- CameraSystem ------------------------------------
    if enable_camera_rot then

        -- Usually, Role 0 is the Main/Player camera.
        -- You can verify the number in the REFramework 'Enums' explorer.
        local camera_obj = camera_system:call("getCameraObject", 0)

        if camera_obj then
            -- Now you can get the Transform to see where it's pointing
            local transform = camera_obj:call("get_Transform")
            if transform then
                -- --local pos = transform:call("get_Position")
                local rot = transform:call("get_Rotation")

                local yaw, pitch = quaternion_to_euler_fixed(rot)

                local rot_text = string.format("Cam Angles: Yaw: %.4f, Pitch: %.4f", yaw, pitch)
            
                -- 2. Calculate coordinates (Percentage * Resolution)
                local draw_x = screen_size.x * text_cam_x
                local draw_y = screen_size.y * text_cam_y

                -- 3. Draw
                imgui.push_font(big_font)
                draw.text(rot_text, draw_x, draw_y, 0xFFFFFFFF)
                imgui.pop_font()

                --log.debug(string.format("Cam Angles - Yaw: %.4f, Pitch: %.4f", yaw, pitch))

            end
        end
    end


    ---------------------- Gravity Manip --------------------------------------
    --setGravityRate(System.Single)
    --resetGravityRate()
    if enable_player_gravity then
        char_man:call("set_CurrentGravityRate", grav_rate)
        char_man:call("setGravityRate", grav_rate)
        local curr_gravity = char_man:call("get_CurrentGravityRate")
        log.debug("Gravity: " .. curr_gravity)
    end


    ----------------------  Invincibility ---------------------------------
    if enable_player_invinc then
        player_handle:call("recoveryHitPointFull")
    end
    
end)