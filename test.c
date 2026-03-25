
int my_printf(char *format, ...);

int main(void) {
    // my_printf("00 %x %x %c %d %x %d %d %d %d %d %s %g %s\n", 10, 20, '8', 40, 0xeda000, 60, 70, 80, 90, 100, "Love", 3.14, "Love");
    // my_printf("%s %d %g %p\n", "Love", 10, 2.76, 0x8850);
    my_printf("%g %g %g %g %g %g %g %g %g\n", 1.14, 2.14, 3.14, 4.14, 5.14, 6.14, 7.14, 8.14, 9.14);
    return 0;
}
