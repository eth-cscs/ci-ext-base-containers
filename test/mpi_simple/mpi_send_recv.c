/****************************************************************
 *                                                              *
 * This file has been written as a sample solution to an        *
 * exercise in a course given at the CSCS Summer School.        *
 * It is made freely available with the understanding that      *
 * every copy of this file must include this header and that    *
 * CSCS take no responsibility for the use of the enclosed      *
 * teaching material.                                           *
 *                                                              *
 * Purpose: A program to try MPI_Comm_size and MPI_Comm_rank.   *
 *                                                              *
 * Contents: C-Source                                           *
 ****************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>


int main(int argc, char *argv[])
{
    /* declare any variables you need */
    int rank;
    int size;
    int number;
    MPI_Status status;

    MPI_Init(&argc, &argv);

    /* Get the rank of each process */
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);

    /* Get the size of the communicator */
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    /* Write code such that every process writes its rank and the size of the communicator,
     * but only process 0 prints "hello world*/
    printf("Process %d out of %d.\n", rank, size);

    /* Check communicator size */
    if (size != 2) {
        printf("Error: Proces %d: communicator size %d, expected 2.\n", rank, size);
        MPI_Finalize();
        exit(1);
    }

    /* Check send, receive */
    if (rank == 0) {
        number = 42;
        printf("Process %d: sending number %d\n", rank, number);
        MPI_Send(&number, 1, MPI_INT, 1, 0, MPI_COMM_WORLD);
    }

    if (rank == 1) {
        MPI_Recv(&number, 1, MPI_INT, 0, 0, MPI_COMM_WORLD, &status);
        printf("Process %d: received number %d\n", rank, number);
        if (number != 42) {
            printf("Error: Process %d: received %d, expected 42.\n", rank, number);
            MPI_Finalize();
            exit(1);
        }
    }

    MPI_Finalize();
    return 0;
}
