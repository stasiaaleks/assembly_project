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

    bool operator<(const KeyAverage& other) const {
        return average < other.average;
    }

    bool operator>(const KeyAverage& other) const {
        return average < other.average;
    }

    bool operator<=(const KeyAverage& other) const {
        return (average == other.average || average < other.average);
    }

    bool operator>=(const KeyAverage& other) const {
        return (average == other.average || average > other.average);
    }
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

    void MergeSort(vector<KeyAverage>& arr, int start, int end) //sorts backwards
    {
        if (start < end) {
            int mid = start + (end - start) / 2;
            MergeSort(arr, start, mid);
            MergeSort(arr, mid + 1, end);
            Merge(arr, start, mid, end);
        }
    }

    void Merge(vector<KeyAverage>& arr, int start, int mid, int end)
    {
        int leftArrLength = mid - start + 1; 
        int rightArrLength = end - mid;

        KeyAverage *leftArr = new KeyAverage[leftArrLength];
        KeyAverage* rightArr = new KeyAverage[rightArrLength];
        //vector<KeyAverage> rightArr(rightArrLength);

        for (int i = 0; i < leftArrLength; i++)
            leftArr[i] = arr[start + i]; 
        for (int j = 0; j < rightArrLength; j++)
            rightArr[j] = arr[mid + 1 + j];

        int i = 0;
        int j = 0;
        int k = start;

        while (i < leftArrLength && j < rightArrLength) {
            if (leftArr[i] >= rightArr[j]) {
                arr[k] = leftArr[i]; 
                i++;
            }
            else {
                arr[k] = rightArr[j];
                j++;
            }
            k++;
        }

        while (i < leftArrLength) {
            arr[k] = leftArr[i];
            i++;
            k++;
        }

        while (j < rightArrLength) {
            arr[k] = rightArr[j];
            j++;
            k++;
        }

        delete[] leftArr;
        delete[] rightArr;
    }

    void PrintSortedKeys()
    {
        MergeSort(CompressedVector, 0, CompressedVector.size()-1);

        for (const auto& item : CompressedVector)
        {
            cout << item.key << endl;
        }
    }
};