function RunAutorun()
	local autorun = fs.readdirSync("autorun/")
	table.sort(autorun)
	for _,file in pairs(autorun) do
		if file:find("%.lua$") then
			dofile(file)
		end
	end
end
