Command lines:
  1. template0.pdf
    #./aaron.rb file test.ns --new --pdf --template 0
  
  2. template1.pdf
    #netstat -antu | ./aaron.rb stdin --new --template 1 --pdf
    
  3. template2.pdf
    #./aaron.rb redraw --template 2 --pdf
    
  4. template3.pdf
    #./aaron.rb redraw --template 3 --pdf
    
  5 template4.pdf
    #./aaron.rb redraw --template 4 --pdf

  6. intro1.pdf
    #netstat -antu | ./aaron.rb stdin --project intro.axa --verbose --new
    #./aaron.rb ssh 192.168.56.101 --user root --pass 123456 --project intro.axa --pdf
    
  7. intro2.pdf
    #./aaron.rb redraw --template 0 --project intro.axa --pdf
