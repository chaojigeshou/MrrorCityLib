// MrrorCityLib 冒烟测试构建器
// 用法: node tests/build.js  → 生成 tests/combined.lua, 再交给 luau 执行:
//   luau tests/combined.lua   (期望输出 SMOKE_DONE)
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');
const stub = fs.readFileSync(path.join(__dirname, 'stub.lua'), 'utf8');
const src = fs.readFileSync(path.join(root, 'source.lua'), 'utf8');
const exercise = fs.readFileSync(path.join(__dirname, 'exercise.lua'), 'utf8');

const combined =
	stub +
	'\nlocal __main = function()\n' +
	src +
	'\nend\nlocal Library = __main()\n' +
	'if type(Library) ~= "table" or Library.Version == nil then\n' +
	'  print("LIBRARY_RETURN_BAD"); os.exit(1)\n' +
	'end\n' +
	exercise;

fs.writeFileSync(path.join(__dirname, 'combined.lua'), combined, 'utf8');
console.log('built tests/combined.lua');
