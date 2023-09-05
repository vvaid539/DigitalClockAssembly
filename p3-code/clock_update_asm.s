.text                           # IMPORTANT: subsequent stuff is executable
.global  set_tod_from_ports
        
## ENTRY POINT FOR REQUIRED FUNCTION
set_tod_from_ports:
        ## Access Global Variable and do error checking 
        movl $0, %ecx                           #set ecx equal to 0
        movl $0, %eax                           #set eax to 0
        movl TIME_OF_DAY_PORT(%rip), %ecx       #set ecx equal to time of day port
        cmpl $0, %ecx                           #Compare ecx with less than 0
        jl   .ERRORCHECK
        cmpl $1382400, %ecx                     #Compare ecx with greatest possible value
        jg   .ERRORCHECK
        ## Begin conversion using bitwise operations- Works for day_secs conversion
        movl $0, %r10d                          # set r10d equal to 0
        movl %ecx, %r10d                        # set r10d to ecx
        shr  $4, %r10d                          # shift it right 4
        movl $0, %r11d                          # move 0 into rlld
        movl %ecx, %r11d                        # moves ecx into rlld
        shr  $3, %r11d                          # shift right by 3
        and  $1, %r11d                          # Ands all the values with 1
        add  %r11d, %r10d                       # adds the struct to the its spot
        movl %r10d, %eax                        # moves r10d into eax
        movl %r10d, 0(%rdi)                     # sets it in the struct
        movl %eax, %r8d                         # moves eax into r8d
        ## Conversion for the time_hours
        movl $0, %eax                           # set eax to 0
        movl $0, %r11d                          # set rlld to 0
        movl %r10d, %eax                        # move the information into eax to prep for divsion
        cqto                                    # needed for division
        movl $3600, %r11d                       # create the divisor
        idivl %r11d                             # complete the division
        ## Changing hours based on whether AMPM
        cmpl $12, %eax                          # comparison to determine AMPM
        jl   .AM                                # jump to AM
        jge  .PM                                # jump to PM


.DETERMINEREMAINING:
        movl $0, %eax                           # move 0 into eax
        movl %r8d, %eax                         # move r7d into eax
        cqto                                    # needed for division
        movl $3600, %r9d                        # moves 2600 into divisor
        idivl %r9d                              # does the division
        movl %edx, %eax                         # moves the remaindered value in to eax
        cqto                                    # needed for division
        movl $60, %r9d                          # moves 60 into divisor for second division
        idivl %r9d                              # does the division
        movw %ax, 6(%rdi)                       # move the struct value in struct
        movl %r8d, %eax                         # reset eax to the struct 
        cqto                                    # needed for division
        movl $60, %r9d                          # set divisor to 60
        idivl %r9d                              # complete the division
        movw %dx, 4(%rdi)                       # move struct value into struct
        movl $0, %eax                           # set return value equal to 0
        ret                                     # return 0

.DETERMINEHOURS:
        movw %ax, 8(%rdi)                # sets hour value to the struct if none of the following cases apply
        cmpl $0, %eax                    # determines if hour value is set to 0
        je  .CHANGEHOURS                 # jumps to changehours
        cmpl $12, %eax                   # determines if the hour value is greater than 12
        jg  .CHANGEHOURSOTHER            # jumnps to change hours other
        jmp .DETERMINEREMAINING          # jumps to determine the rest of the struct

.ERRORCHECK:
        movl $1, %eax                   # moves one into eax if error is found
        ret                             # returns one and breaks system

.AM:
        movb $1,10(%rdi)                # moves one in the struct to represent PM
        jmp .DETERMINEHOURS             # jumps to determing the hours in the struct

.PM: 
        movb $2,10(%rdi)                 # moves two in the struct to represent PM    
        jmp .DETERMINEHOURS              # jumps to determing the hours in the struct

.CHANGEHOURS:
        movw $12, 8(%rdi)               # normal hour change in AM - no subtraction necessary
        jmp .DETERMINEREMAINING         # jump to fill out the rest of the struct

.CHANGEHOURSOTHER:      
        sub  $12, %eax                  # subtract 12 from the eax value to get PM value
        movw %ax, 8(%rdi)               # moves correct hours into the struct
        jmp .DETERMINEREMAINING         # jump to fill out rest of struct


### Data area associated with the next function
.data                           # IMPORTANT: use .data directive for data section
	
my_int:                         # declare location an single int
        .int 1234               # value 1234

other_int:                      # declare another accessible via name 'other_int'
        .int 0b0101             # binary value as per C '0b' convention

my_array: 
                                        # declare multiple ints in a row 
        .int 0b1110111                 # for an array. Each are spaced
        .int 0b0100100                 # 4 bytes from each other
        .int 0b1011101
        .int 0b1101101
        .int 0b0101110
        .int 0b1101011
        .int 0b1111011
        .int 0b0100101
        .int 0b1111111
        .int 0b1101111


.text                           # IMPORTANT: switch back to executable code after .data section
.global  set_display_from_tod

## ENTRY POINT FOR REQUIRED FUNCTION
set_display_from_tod:
        ## Error checking comparisons
        jmp .ERRORTEST
.DISPLAYINTEGEROPS:
        movl $0, %ecx           # temp variable 
        movq %rdx, %r11
        movl $0, %edx           # set rdx to 0
        movl $0, %eax           # set rax to 0
        movl $0, %r10d          # Precautionary Measure
        movl $0, %r9d           # Precautionary Measure
        movl $0, %r8d           # Precautionary Measure
        leaq my_array(%rip), %r9   # Set array

        movq %rdi, %rax         # Move the rdi values into rax
        sarq $48, %rax          # Shift right 48 bits
        andq $0xFFFF, %rax      # Compare first 16 bits to all 1's

        ##Calculate what is necessary for mins-tens
        cqto 
        movl $10, %r8d             # Set 10 as the divisor
        idivl %r8d                 # Complete division
        movl (%r9,%rax,4),%r10d    # Determine what array value to get SEG FAULT HERE
        sall $7, %r10d             # Shift bits into proper spot
        orl  %r10d, %ecx           # Move bits into temporary variable

        ## Calculate what is necessary for mins - ones
        movl (%r9,%rdx,4),%r10d    # Shift bits into proper spot
        orl  %r10d, %ecx           # Move bits into temporary variable

        ## Calculate what is necessary for hours 
        movq $0, %rax           # set rax to 0
        movq $0, %rdx           # set rdx to 0
        movq $0, %r10           # Precautionary Measure
        movq $0, %r8            # Precautionary Measure

        movq %rsi, %rax         # Move the rsi values into rax
        andq $0xFFFF, %rax      # Compare first 16 bits to all 1'ss

        cqto
        movq $10, %r8              # Set 10 as the divisor
        idivq %r8                  # Complete division
        movl (%r9,%rdx,4),%r10d    # Determine what array value to get
        sall $14, %r10d            # Shift bits into proper spot
        orl  %r10d, %ecx           # Move bits into temporary variable

        cmpq $0, %rax
        jne  .ADDTENTHS

        ##Change for AMPM
.AMPMS:
        movq $0, %rax           # set rax to 0
        movq $0, %rdx           # set rdx to 0
        movq $0, %r10           # Precautionary Measure
        movq $0, %r8            # Precautionary Measure

        movq %rsi, %rax         # Move the rdi values into rax
        sarq $16, %rax          # Shift right 416 bits
        andq $0xFF, %rax        # Compare first 8 bits to all 1's

        movq $1, %r10           # moves 1 into rd10
        cmpq $2, %rax           # compares with 2
        je .PMS                 # if equals, jump to PM
        cmpq $1, %rax           # compares with 1
        je .AMS                 # if equals, jump to AM

        
.PMS:
        sall $29, %r10d         #shift left 29 bits
        orl  %r10d, %ecx        #add it to temp variable
        jmp .FINISH             #jumps to end
.AMS: 
        sall $28, %r10d         #shift left 28 bits
        orl  %r10d, %ecx        #add it to temp variable
        jmp .FINISH             #jump to the end
        
.ADDTENTHS:
        movl (%r9,%rax,4),%r10d    ## Determine what array value to get
        sall $21, %r10d            ## Shift bits into proper spot
        orl  %r10d, %ecx           ## Move bits into temporary variable
        jmp .AMPMS

.FINISH: 
        movl %ecx, (%r11)          # move temp variable to pointer 
        movq $0, %rax              # set return value to 0
        ret                        # return 0

       
.ERRORTEST:
        ##Error checking the day->secs
        cmpl $89600, %edi               # compare with 89600
        jg .ERRORS                      # if greater, jump to errors
        cmpl $0, %edi                   # compares with 1
        jl .ERRORS                      #if less than, jump to errors
        ##Error checking the time->secs
        movq $0, %rcx                   # move 0 in to rcx
        movq %rdi, %rcx                 # move rdi into rcx
        shr  $32, %rcx                  # shift the bits right by 32
        cmpw $59, %cx                   # compare with 59
        jg   .ERRORS                    # if greater, jump to errors
        cmpw $0, %cx                    # compare with 1
        jl   .ERRORS                    # if less. jump to errors
        ##Error checking for time->mins
        movq $0, %rcx                   # move 0 in to rcx
        movq %rdi, %rcx                 # move rdi into rcx
        shr  $48, %rcx                  # shift bits right by 48
        cmpw $59, %cx                   # compare with 59
        jg   .ERRORS                    # if greater, jump to error's
        cmpw $0, %cx                    # compare with 0
        jl   .ERRORS                    # if less, jump to errors
        ## Error checking for time->hours
        movq $0, %rax                   # move 0 in to rax
        movq %rsi, %rcx                 # move rdi into rcx
        cmpw $12, %cx                   # compare with 12
        jg   .ERRORS                    # if greater than, jump to errors
        cmpw $0, %cx                    # compare with 0
        jl   .ERRORS                    # if less than, jump to errors
        ## Error checking for time->AMPM  
        movq $0, %rcx                   # move 0 in to rcx
        movq %rsi, %rcx                 # move rdi into rcx
        shr  $16, %rcx                  # shift right by 16 bits
        cmpb $1, %cl                    # compare with 1
        jl   .ERRORS                    # if less than, jump to errors
        cmpb $2, %cl                    # compare with 2
        jg   .ERRORS                    # if greater than, jump to errors
        jmp  .DISPLAYINTEGEROPS         # continue to setting dispplay integer

.ERRORS:
        movl $1, %eax                   #Sets return value to 1
        ret                             #returns 1

.text
.global clock_update
        
## ENTRY POINT FOR REQUIRED FUNCTION
clock_update:
        movl $0, %eax
        subq $24, %rsp                  #Put zero tod struct on stack, extend stack by 8 for function call
        leaq  (%rsp), %rdi              #Makes rdi the zero struct

        call set_tod_from_ports         #Function call
        cmpl $1, %eax                    #error check
        je .FAIL

        movq (%rsp), %rdi               #transfer pointer to struct
        movq 8(%rsp), %rsi
        leaq CLOCK_DISPLAY_PORT(%rip),%rdx        #Into the struct itself

        call set_display_from_tod       #Function call
        cmpl $1, %eax                    #error check
        je .FAIL

        movl $0, %eax                   #Return 0
        addq $24, %rsp                   #Shrink stack to restore to initial position
        ret 

.FAIL:
        movl $1, %eax                   #Return 1
        addq $24, %rsp                   #Shrink stack to restore to initial position
        ret                             #Returns this value