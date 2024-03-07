#pragma once
#include <iostream>
#include <fstream>
#include <string>
using namespace std;

static void ReadFile(string filepath)
{
    string StringFromFile;
    ifstream ReadFile(filepath);

    while (getline(ReadFile, StringFromFile)) {
        cout << StringFromFile << endl;
    }

    ReadFile.close();
}
