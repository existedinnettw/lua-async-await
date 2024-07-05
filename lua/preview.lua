local t = require "tutorial"
local uv = require('luv')
local a = require("async")

--   0
-- /   \ 
-- 03s 08s
-- |    |
-- 06s  |
-- \   /
-- after_merge

local timeout = function(ms, callback)
    local timer = uv.new_timer()
    uv.timer_start(timer, ms, 0, function()
        uv.timer_stop(timer)
        uv.close(timer)
        callback()
    end)
end

local sleep_for_t = function(ms, callback)
    -- wait 200ms
    timeout(ms, function()
        -- print("sleep for called")
        callback() -- why callback is necessay?
    end)
end
local sleep_for = a.wrap(sleep_for_t)

local tcp_req_t = function(callback)

    local client = uv.new_tcp()
    uv.tcp_connect(client, "45.79.112.203", 4242, function(err)
        assert(not err, err)

        uv.read_start(client, function(err, chunk)
            print("received at client:", chunk)
            assert(not err, err)
            if chunk then
                uv.shutdown(client)
                print("client done shutting down")
            else
                uv.close(client)
                callback() --this will continue subsequence, iff cb finished
            end
            -- callback() --error
        end)

        uv.write(client, "Hello\n", function(err)
            print("write `Hello` complete")
        end)
        uv.write(client, "World\n")

        print("writing from client")
        -- callback()
    end)
end
local tcp_req = a.wrap(tcp_req_t)

local task_0 = function()
    return a.sync(function()
        print("task_0 done")
    end)
end

local task_01s = function()
    return a.sync(function()
        a.wait(sleep_for(100))
        print("task_01s done")
    end)
end

local task_03s = function()
    return a.sync(function()
        a.wait(sleep_for(300))
        print("task_03s done")
    end)
end

local task_06s = function()
    return a.sync(function()
        a.wait(sleep_for(600))
        print("task_06s done")
    end)
end

local task_08s = function()
    return a.sync(function()
        a.wait(sleep_for(800))
        print("task_08s")
        return
    end)
end

local left_branch = function()
    return a.sync(function()
        a.wait(tcp_req())
        a.wait(task_01s())
        -- a.wait(task_03s())
        a.wait(task_06s())
    end)
end

local right_branch = function()
    return a.sync(function()
        a.wait(task_08s())
        return
    end)
end

local after_merge = function()
    return a.sync(function()
        print("after_merge")
    end)
end

local main = a.sync(function()
    a.wait(task_0())
    a.wait_all {left_branch(), right_branch()}
    a.wait(after_merge())
end)

-- t.async_example()()
main()

uv.run()
