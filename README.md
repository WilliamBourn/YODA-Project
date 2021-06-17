# YODA-Project: Arithmetic Series Generator

The project should be tested using the Vivado 2019.2 design suite.

A testbench is available for performing a timing analysis. The inputs of the ASG can be set using the a1_in, d_in, n_in and saddr_in registers in the testbench initial block and should result in an arithmetic series of the for:

am = a1_in (m - 1)*d, where m are the values in the range 1 to n_in. The series will have an associated address of saddr_in + 8*(m-1).
