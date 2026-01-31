let run_tests dir =
  let files = Sys.readdir dir in
  Array.sort String.compare files;
  Array.iter (fun file ->
    if String.length file >= 7 && String.sub file 0 7 = "torture" then
      Printf.printf "\n\n--- RUNNING: %s ---\n" file;
      try
        test (file_to_string (Filename.concat dir file))
      with e ->
        Printf.printf "Error while running test %s: %s\n" file (Printf.sprintf "%s" (Printexc.to_string e))
  ) files;;

let () = run_tests "tests";;