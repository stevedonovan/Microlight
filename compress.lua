io.output 'compressed/ml.lua'
for line in io.lines 'ml.lua' do
   if not (line:match '^%s*$' or line:match '^%-%-') then
	line = line:gsub('^%s*','')
	io.write(line,'\n')
   end
end
io.close()

