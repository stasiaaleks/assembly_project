#pragma once
#include <iostream>
#include <fstream>
#include <string>
#include <sstream>
#include <vector>
using namespace std;

struct KeySumCounter
{
    string key;
    int sum;
    int keyCounter;
};

struct KeyAverage
{
    string key;
    double average;
};


class FileReader {
    vector<KeySumCounter> ParsedFileVector;
    vector<KeyAverage> CompressedVector;


public:
    void ParseFile(string filepath)
    {
        string StringFromFile;
        ifstream ReadFile(filepath);

        while (getline(ReadFile, StringFromFile)) {
            stringstream ss(StringFromFile);
            string keyFromFile, valueStr;
            int value;

            ss >> keyFromFile;
            ss >> valueStr;

            //setting valueStr to value
            try {
                value = stoi(valueStr);
                if (value >= 10000 && value <= -10000)
                {
                    cout << "Value out of range" << endl;
                }

            }
            catch (const std::invalid_argument& e) {
                cout << "Invalid value argument" << endl;
            }

            if (ParsedFileVector.empty())
            {
                ParsedFileVector.push_back({ keyFromFile, value, 1 });
                continue;
            }

            bool foundKey = false;

            for (int i = 0; i < ParsedFileVector.size(); i++)
            {
                KeySumCounter& item = ParsedFileVector[i];
             
                if (item.key == keyFromFile)
                {
                    item.sum += value; //adding another value to sum
                    item.keyCounter++; //incrementing key counter
                    foundKey = true;
                    break;
                }
            }

            if (!foundKey) ParsedFileVector.push_back({ keyFromFile, value, 1 });

        }

        ReadFile.close();

        for (const auto& item : ParsedFileVector)
        {
            double average = (double)item.sum / (double)item.keyCounter;
            CompressedVector.push_back({ item.key, average });
        }

    }

};