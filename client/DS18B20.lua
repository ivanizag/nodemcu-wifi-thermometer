
function ds18b20_bxor(a,b)
    local r = 0
    for i = 0, 31 do
        if ( a % 2 + b % 2 == 1 ) then
            r = r + 2^i
        end
        a = a / 2
        b = b / 2
    end
    return r
end

function ds18b20_measures(pin, powerpin)
    readings =  {}

    ow.setup(pin)
    gpio.mode(powerpin, gpio.OUTPUT)
    gpio.write(powerpin, gpio.HIGH)

    ow.reset_search(pin)
    local addr = ow.search(pin)
    repeat
        tmr.wdclr()

        if (addr ~= nil) then
            local crc = ow.crc8(string.sub(addr,1,7))
            if (crc == addr:byte(8)) then
                if ((addr:byte(1) == 0x10) or (addr:byte(1) == 0x28)) then
                    ow.reset(pin)
                    ow.select(pin, addr)
                    ow.write(pin, 0x44, 1)
                    tmr.delay(1000000)

                    ow.reset(pin)
                    ow.select(pin, addr)
                    ow.write(pin,0xBE, 1)

                    local data = string.char(ow.read(pin))
                    for i = 1, 8 do
                        data = data .. string.char(ow.read(pin))
                    end
                    crc = ow.crc8(string.sub(data,1,8))
                    if (crc == data:byte(9)) then
                        local t = (data:byte(1) + data:byte(2) * 256)
                        if (t > 32768) then
                            t = (ds18b20_bxor(t, 0xffff)) + 1
                            t = (-1) * t
                        end
                        t = t * 625
                        -- Assumes there could be no float support on firmware
                        local t1 = (t >= 0 and math.floor(t / 10000)) or math.ceil(t / 10000)
                        local t2 = (t >= 0 and t % 10000) or (10000 - t % 10000)
                        local temp = (t1 .. "." .. string.format("%04d", t2))
                        local device = string.format("%02x%02x%02x%02x%02x%02x%02x%02x", addr:byte(1,8))
                        print("Device " .. device .. " reads " .. temp .. "C. Raw: " .. t)
                        readings[device] = temp
                    end
                    tmr.wdclr()
                end
            end
        end
        addr = ow.search(pin)
    until(addr == nil)

    gpio.write(powerpin, gpio.LOW)
    return readings
end

function ds18b20_sleep()
   if gpio.read(3) == 0 then
    print("FLASH button is pushed. Deep sleep aborted.")
  else
    print("Going to deep sleep .")
    node.dsleep(60*1000*1000)
  end
end

function ds18b20_read_send_sleep(server, port, pin, powerpin)
  -- To deep sleep after 10 seconds no matter what.
  tmr.alarm(0, 10 * 1000, tmr.ALARM_SINGLE, function()
    print("Too long awake.")
    ds18b20_sleep()
  end)

  local readings = ds18b20_measures(pin, powerpin)

  -- Send the info on wifi ready
  tmr.alarm(1, 1000, tmr.ALARM_AUTO, function()
    if wifi.sta.status() == 5 then
      tmr.stop(1)
      ds18b20_sendMeasures(server, port, readings)
    elseif wifi.sta.status() >= 2 then
      print("Wifi not available.")
      ds18b20_sleep()
    else
      print("Wifi not ready. waiting.")
    end
  end)
end

function ds18b20_sendMeasures(server, port, readings)
  local conn = net.createConnection(net.TCP)
  conn:on("connection", function(conn)
    print("Connected")
    local msg = ""
    for k, v in pairs(readings) do
      local counter = "home.nodemcu.temperature.sensor"
      msg = msg .. "home.nodemcu.temperature.sensor" .. k .. ":" .. v .. "|ms\r\n"
    end
    print("Sending: " .. msg)
    conn:send(msg)
  end)
  conn:on("sent", function(conn)
    print("Sent.")
    ds18b20_sleep()
  end)
  print("Connecting to " .. server .. ":" .. port .. " from " .. wifi.sta.getip())
  conn:connect(port, server)
end

