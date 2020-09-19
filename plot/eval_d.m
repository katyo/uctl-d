function data = eval_d(code, varargin)
  code = [code "\n"];
  i = 1;
  while i <= length(varargin)
    var = varargin{i};
    i++;
    if !ischar(var)
      error(["Variable name expected at position: " num2str(i)]);
    endif
    var = strsplit(var, " ");
    type = "real";
    if length(var) == 1
      var = var{1};
    else
      type = var{1};
      var = var{2};
    endif
    val = varargin{i}; i++;
    if ischar(val)
      code = [code "alias "];
    elseif isnumeric(val)
      dim = size(val);
      if dim(1) == 1 && dim(2) == 1
        val = num2str(val);
        code = [code "enum " type];
      elseif dim(1) == 1 || dim(2) == 1
        cval = arrayfun(@(num) num2str(num), val, "UniformOutput", false);
        val = ["[" strjoin(cval, ", ") "]"];
        code = [code "immutable " type "[" num2str(dim(1) * dim(2)) "]"];
      else
        cval = arrayfun(@(num) num2str(num), val, "UniformOutput", false);
        val = ["[\n  [" strjoin(cval(1, :), ", ") "]"];
        for n = 2:length(cval)
          val = [val ",\n  [" strjoin(cval(n, :), ", ") "]"];
        endfor
        val = [val "\n]"];
        code = [code "immutable " type "[" num2str(dim(1)) "][" num2str(dim(2)) "]"];
      endif
    endif
    code = [code " " var " = " val ";\n"];
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
