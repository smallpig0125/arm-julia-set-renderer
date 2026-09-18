#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>

#define FRAME_WIDTH     640
#define FRAME_HEIGHT    480

#define FRAME_BUFFER_DEVICE "/dev/fb0"

/*************************************************************
 *  <<Julia set相關資料>>
 *  https://en.wikipedia.org/wiki/Julia_set
 *
 *  cX 為 Julia set數學式中複數 "c" 的實部
 *  cY 為 Julia set數學式中複數 "c" 的虛部
 *  調整cX(值域:-1.0~1.0)與cY(值域:0.0~1.0)可得到不同的圖形
*************************************************************/

void drawJuliaSet(int cX, int cY, int width, int height, int16_t (*frame)[FRAME_WIDTH]);

int main() {
    // 定義畫面緩衝區
    int16_t frame[FRAME_HEIGHT][FRAME_WIDTH] = {0};

    int max_cX = -700;
    int min_cY = 270;

    int cY_step = -5;
    int cX = -700;    // x = -700
    int cY;           // y = 400~270

    int fd;

    printf("Function1: Name\n");
    NAME();

    printf("Function2: ID\n");
    ID();

    printf("\n***** Please enter p to draw Julia Set animation *****\n");
    while (getchar() != 'p') {}

    // 清除畫面
    system("clear");

    // 嘗試打開 Frame Buffer 設備節點
    fd = open(FRAME_BUFFER_DEVICE, (O_RDWR | O_SYNC));
    if (fd < 0) {
        perror("Frame Buffer Device Open Error");
        printf("改為儲存到檔案...\n");
    }

    // 繪製 Julia Set 並顯示動畫
    for (cY = 400; cY >= min_cY; cY += cY_step) {

        // 計算目前 cX, cY 參數下的 Julia set 畫面
        drawJuliaSet(cX, cY, FRAME_WIDTH, FRAME_HEIGHT, frame);
        // 若無法使用 Frame Buffer，則改為存檔
        if (fd < 0) {
            FILE *output = fopen("output.ppm", "wb");
            if (output == NULL) {
                perror("File Open Error");
                return 1;
            }
            int y = 0, x = 0;
            fprintf(output, "P6\n%d %d\n255\n", FRAME_WIDTH, FRAME_HEIGHT);
            for (; y < FRAME_HEIGHT; y++) {
                for (; x < FRAME_WIDTH; x++) {
                    uint16_t color = frame[y][x];
                    fputc((color >> 8) & 0xFF, output);  // R
                    fputc((color >> 8) & 0xFF, output);  // G
                    fputc((color >> 8) & 0xFF, output);  // B
                }
            }
            fclose(output);
            printf("Julia Set saved to output.ppm\n");
            break;
        } else {
            // 將畫面資料寫入 Frame Buffer
            if (write(fd, frame, sizeof(int16_t) * FRAME_HEIGHT * FRAME_WIDTH) < 0) {
                perror("Frame Buffer Write Error");
                close(fd);
                return 1;
            }

            // 重置檔案指標以便重新寫入
            lseek(fd, 0, SEEK_SET);
        }
    }

    if (fd >= 0) {
        close(fd);
    }

    printf(".*.*.*.<:: Happy New Year ::>.*.*.*.\n");
    printf("by Team 15\n");
    printf("11227125   CHAO, HSUAN-CHENG\n");
    printf("11227141   CHUNG, PO-CHUN\n");
    printf("11227125   CHAO, HSUAN-CHENG\n");

    // 等待使用者輸入正確指令
    while (getchar() != 'p') {}

    return 0;
}
