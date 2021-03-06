--!A cross-platform build utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        inf.lua
--

-- define rule: *.inf
rule("wdk.inf")

    -- add rule: wdk environment
    add_deps("wdk.env")

    -- set extensions
    set_extensions(".inf", ".inx")

    -- on load
    on_load(function (target)

        -- imports
        import("core.project.config")

        -- get arch
        local arch = assert(config.arch(), "arch not found!")
        
        -- get stampinf
        local stampinf = path.join(target:data("wdk").bindir, arch, "stampinf.exe")
        assert(stampinf and os.isexec(stampinf), "stampinf not found!")
        
        -- save uic
        target:data_set("wdk.stampinf", stampinf)
    end)

    -- on build file
    on_build_file(function (target, sourcefile, opt)

        -- imports
        import("core.base.option")
        import("core.project.depend")

        -- the target file
        local targetfile = path.join(target:targetdir(), path.basename(sourcefile) .. ".inf")

        -- add clean files
        target:data_add("wdk.cleanfiles", targetfile)

        -- need build this object?
        local dependfile = target:dependfile(targetfile)
        local dependinfo = option.get("rebuild") and {} or (depend.load(dependfile) or {})
        if not depend.is_changed(dependinfo, {lastmtime = os.mtime(targetfile)}) then
            return 
        end

        -- trace progress info
        if option.get("verbose") then
            cprint("${green}[%02d%%]:${dim} compiling.wdk.inf %s", opt.progress, sourcefile)
        else
            cprint("${green}[%02d%%]:${clear} compiling.wdk.inf %s", opt.progress, sourcefile)
        end

        -- get stampinf
        local stampinf = target:data("wdk.stampinf")

        -- update the timestamp
        os.cp(sourcefile, targetfile)
        os.vrunv(stampinf, {"-d", "*", "-a", is_arch("x64") and "arm64" or "x86", "-v", "*", "-f", targetfile}, {wildcards = false})

        -- update files and values to the dependent file
        dependinfo.files = {sourcefile}
        depend.save(dependinfo, dependfile)
    end)

