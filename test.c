
int my_printf(char *format, ...) __attribute__((format(printf, 1, 2)));

int main(void) {
    double pir = 3.14;
    my_printf("00 %x %d %c %d %x %d %d %d %d %d %s %g %s\n", 10, 20, '8', 40, 0xeda000, 60, 70, 80, 90, 100, "Love", 3.14, "Love");
    my_printf("%s %d %g %p %d\n", "Love", 10, 2.76, 0x8850, 102);
    // my_printf("%g", pir);
    // my_printf("%x %x %c %d %x %d %d %d %d %d %s %x %d%%%c%b %d %d\n ",
        // 10, 20,'8', 40, 0xeda000, 60, 70, 80, 90, -1, "Love", 100, 126, 127, 128, 129, 120);

    return 0;
}
