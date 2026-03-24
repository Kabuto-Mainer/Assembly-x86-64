
int my_printf(char *format, ...);

int main(void) {
    my_printf("00 %x %x %c %d %x %d %d %d %d %d %s %g %s\n", 10, 20, '8', 40, 0xeda000, 60, 70, 80, 90, 100, "Love", 3.14, "Love");
    return 0;
}
