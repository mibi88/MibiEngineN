/* Small demo for christmas 2025.
 *
 * by Mibi88
 *
 * This software is licensed under the BSD-3-Clause license:
 *
 * Copyright 2025 Mibi88
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 * contributors may be used to endorse or promote products derived from this
 * software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#include <stdio.h>
#include <stdlib.h>

/* Compresses data with RLE */

int main(int argc, char **argv) {
    unsigned char *buffer;
    size_t size;

    if(argc < 3){
        fprintf(stderr, "USAGE: %s [INPUT] [OUTPUT]\n"
                        "A small RLE compression utility\n", argv[0]);

        return EXIT_FAILURE;
    }

    /* Load the input file */
    {
        FILE *fp;

        fp = fopen(argv[1], "rb");
        if(fp == NULL){
            fprintf(stderr, "%s: Failed to open %s!\n", argv[0], argv[1]);

            return EXIT_FAILURE;
        }

        fseek(fp, 0, SEEK_END);
        size = ftell(fp);
        rewind(fp);

        buffer = malloc(size);
        if(buffer == NULL){
            fprintf(stderr, "%s: Failed to allocate %lu bytes!\n", argv[0],
                    size);

            fclose(fp);

            return EXIT_FAILURE;
        }

        fread(buffer, 1, size, fp);

        fclose(fp);
    }

    /* Write the output file */
    {
        FILE *fp;
        unsigned char count = 0;
        size_t i;

        fp = fopen(argv[2], "wb");
        if(fp == NULL){
            fprintf(stderr, "%s: Failed to open %s!\n", argv[0], argv[2]);

            free(buffer);
            return EXIT_FAILURE;
        }

        if(!size){
            printf("%s: Warning: empty input file!\n", argv[0]);

            fwrite(&count, 1, 1, fp);

            fclose(fp);
            free(buffer);

            return EXIT_SUCCESS;
        }

        count = 1;
        for(i=1;i<size;i++){
            if(buffer[i] != buffer[i-1] || count == 255){
                fwrite(&count, 1, 1, fp);
                fwrite(buffer+i-1, 1, 1, fp);
                count = 0;
            }
            count++;
        }

        fwrite(&count, 1, 1, fp);
        fwrite(buffer+i-1, 1, 1, fp);

        count = 0;
        fwrite(&count, 1, 1, fp);

        fclose(fp);
    }

    free(buffer);

    return EXIT_SUCCESS;
}
