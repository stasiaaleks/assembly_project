#include "FileReader.h"

int main() {
    FileReader fr;
    fr.ParseFile("test.txt");
    fr.PrintSortedKeys();

    return 0;
}

