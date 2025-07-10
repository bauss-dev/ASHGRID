/**
* Copyright © ASHGRID 2025
* License: MIT (https://github.com/bauss-dev/ASHGRID/blob/main/LICENSE)
* Author: Jacob Jensen (bauss-dev)
*/
module ashgrid.functions;

/// Creates a coordinate array.
T[] createCoordinateArray(T)(int width, int height)
{
    return new T[width * height];
}

/// Gets the coordinate index to a coordinate array.
int getCoordinateIndex(int width, int x, int y)
{
    return x + width * y;
}

/// Gets the coordinate from a coordinate array.
T getCoordinate(T)(T[] array, int width, int x, int y)
{
    return array[getCoordinateIndex(width, x, y)];
}

/// Gets the coordinates from a coordinate array based on a given index.
void getCoordinates(int width, int index, out int x, out int y)
{
    x = index % width;
    y = index / width;
}

/// Checks whether something is in bounds.
bool isInBounds(int x, int y, int width, int height)
{
    return x >= 0 && y >= 0 && x < width && y < height;
}

/// Generates a smooth noise value based on a given seed and offset.
float smoothNoise(int x, int y, uint seed, int offset = 0)
{
    float randomValue(int x, int y, uint seed, int offset = 0)
    {
        int n = (x + offset) * 374761393 + (y + offset) * 668265263 + cast(int)seed * 1274126177;
        n = (n ^ (n >> 13)) * 1274126177;
        n = n ^ (n >> 16);
        return (n & 0x7fffffff) / cast(float)0x7fffffff;
    }

    float corners = (randomValue(x-1, y-1, seed, offset) + randomValue(x+1, y-1, seed, offset) +
                    randomValue(x-1, y+1, seed, offset) + randomValue(x+1, y+1, seed, offset)) / 16.0f;
    float sides   = (randomValue(x-1, y, seed, offset) + randomValue(x+1, y, seed, offset) +
                    randomValue(x, y-1, seed, offset) + randomValue(x, y+1, seed, offset)) / 8.0f;
    float center  =  randomValue(x, y, seed, offset) / 4.0f;
    return corners + sides + center;
}