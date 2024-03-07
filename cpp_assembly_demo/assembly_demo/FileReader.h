#pragma once
#include <iostream>
#include <fstream>
#include <string>
#include <sstream>
#include <vector>
#include <map>
using namespace std;


static void ReadFile(string filepath)
{
    string StringFromFile;
    ifstream ReadFile(filepath);
    map<string, int> FileMap;

    while (getline(ReadFile, StringFromFile)) {
        // cout << StringFromFile << endl; //output for test

        stringstream ss(StringFromFile);
        string key, valueStr;
        int value;

        ss >> key;
        ss >> valueStr;

        try {
            value = stoi(valueStr);
            if (value <= 10000 && value >= -10000)
            {
                FileMap[key] = value;
            }
            else cout << "Value out of range" << endl;
            
        }
        catch (const std::invalid_argument& e) {
            cout << "Invalid value argument" << endl;
        }

    }

    ReadFile.close();
}
