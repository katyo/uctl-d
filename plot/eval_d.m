function data = eval_d(varargin)
  code = "nothrow @nogc extern(C) void main() { import core.stdc.stdio: printf; ";
  i = 1;
  while i <= length(varargin)
    arg = varargin{i};
    i++;
    if isnumeric(arg)
      arg = num2str(arg);
    endif
    code = [code arg];
  endwhile
  code = [code " }"];

  src_name = "tmp.d";
  src_file = fopen(src_name, "w");
  fputs(src_file, code);
  fclose(src_file);

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
  delete(bin_name);
endfunction
