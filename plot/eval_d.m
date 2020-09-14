function data = eval_d(code, varargin)
  code = [code "\n"];
  i = 1;
  while i <= length(varargin)
    var = varargin{i};
    i++;
    if !ischar(var)
      error(["Variable name expected at position: " num2str(i)]);
    endif
    val = varargin{i}; i++;
    if ischar(val)
      code = [code "alias "];
    elseif isnumeric(val)
      val = num2str(val);
      code = [code "enum auto "];
    endif
    code = [code var " = " val ";\n"];
  endwhile
  code = [code "import core.stdc.stdio: printf;\n" "nothrow @nogc extern(C) void main() { entry(); }\n"];

  src_name = "tmp.d";
  src_file = fopen(src_name, "w");
  fputs(src_file, code);
  fclose(src_file);

  obj_name = "tmp.o";
  bin_name = "tmp.x";
  cmd = ["ldc2 -I. -I.. -of=" bin_name " -d-debug -betterC -nogc -O5 -release " src_name];
  [status, ~] = system(cmd);
  if status != 0
    error("Compilation error occurred");
  endif

  [status, data] = system(["./" bin_name]);
  if status != 0
    error("Execution error occurred");
  endif

  delete(src_name);
  delete(obj_name);
  delete(bin_name);
endfunction
