function dcib
  if test (count $argv) -eq 0
    echo 'No container specified'
  else
    docker exec -it $argv bash
  end
end
