/**
* Copyright © ASHGRID 2025
* License: MIT (https://github.com/bauss-dev/ASHGRID/blob/main/LICENSE)
* Author: Jacob Jensen (bauss-dev)
*/
module ashgrid.generators;

import std.array : array;
import std.random : Random, uniform;
import std.algorithm : clamp;
import std.random : Random, uniform;
import std.algorithm.comparison : min, max;

import ashgrid.enums;
import ashgrid.functions;
import ashgrid.types;

/// Generates a coordinate array of biomes based on given biome weights.
TBiome[] generateBiomes(TBiome = Biome)(MapSettings settings, float[Biome] biomeWeights, int noiseOffset = 0)
{
    TBiome getBiomeFromNoiseValue(TBiome = Biome)(float val, float[TBiome] biomeWeights)
    {
        float totalWeight = 0;
        foreach (weight; biomeWeights)
            totalWeight += weight;

        float cumulative = 0;
        foreach (biome, weight; biomeWeights) {
            cumulative += weight / totalWeight;
            if (val < cumulative)
                return biome;
        }
        return biomeWeights.keys.array[0];
    }

    auto biomes = createCoordinateArray!TBiome(settings.width, settings.height);

    foreach (y; 0 .. settings.width)
    {
        foreach (x; 0 .. settings.height)
        {
            float value = smoothNoise(cast(int)(x / settings.biomeSize), cast(int)(y / settings.biomeSize), settings.seed, noiseOffset);
            auto biome = getBiomeFromNoiseValue!TBiome(value, biomeWeights);
            int index = getCoordinateIndex(settings.width, x, y);

            biomes[index] = biome;
        }
    }

    return biomes;
}

/// Generates a coordinate array of biomes related to a dungeon.
TBiome[] generateDungeon(TBiome = Biome)(MapSettings settings, TBiome emptyBiome, TBiome wallBiome, TBiome groundBiome, int maxRooms = 15, int roomMinSize = 12, int roomMaxSize = 32, int maxAttempts = 0)
{
    if (maxAttempts <= 0)
    {
        maxAttempts = ((roomMinSize + roomMaxSize) / 2) * 45;
        if (maxAttempts < 1) maxAttempts = 1;
    }
    auto dungeon = createCoordinateArray!TBiome(settings.width, settings.height);
    Random rnd = Random(settings.seed + 1337);

    foreach (i; 0 .. dungeon.length)
        dungeon[i] = emptyBiome;

    struct Room
    {
        int x, y, w, h;

        int centerX() => x + w / 2;
        int centerY() => y + h / 2;

        bool intersects(Room other)
        {
            return !(x + w + 1 <= other.x || x >= other.x + other.w + 1 ||
                     y + h + 1 <= other.y || y >= other.y + other.h + 1);
        }
    }

    Room[] rooms;

    const int maxRoomDistance = 30;
    const int maxRoomDistanceSquared = maxRoomDistance * maxRoomDistance;
    const int biasRadius = 25;

    int roomsCreated = 0;
    int attempts = 0;

    while (roomsCreated < maxRooms && attempts < maxAttempts)
    {
        attempts++;

        int w = uniform(roomMinSize, roomMaxSize + 1, rnd);
        int h = uniform(roomMinSize, roomMaxSize + 1, rnd);

        int x, y;
        if (rooms.length == 0)
        {
            x = uniform(1, settings.width - w - 1, rnd);
            y = uniform(1, settings.height - h - 1, rnd);
        }
        else
        {
            auto anchor = rooms[uniform(0, rooms.length, rnd)];
            x = clamp(anchor.centerX() + uniform(-biasRadius, biasRadius + 1, rnd), 1, settings.width - w - 1);
            y = clamp(anchor.centerY() + uniform(-biasRadius, biasRadius + 1, rnd), 1, settings.height - h - 1);
        }

        Room newRoom = Room(x, y, w, h);

        bool overlaps = false;
        foreach (r; rooms)
        {
            if (newRoom.intersects(r))
            {
                overlaps = true;
                break;
            }
        }

        if (overlaps)
            continue;

        Room closest;
        int bestDistance = int.max;
        foreach (r; rooms)
        {
            int dx = newRoom.centerX() - r.centerX();
            int dy = newRoom.centerY() - r.centerY();
            int dist = dx * dx + dy * dy;
            if (dist < bestDistance)
            {
                bestDistance = dist;
                closest = r;
            }
        }

        if (rooms.length == 0 || bestDistance <= maxRoomDistanceSquared)
        {
            foreach (ry; y .. y + h)
            foreach (rx; x .. x + w)
            {
                if (isInBounds(rx, ry, settings.width, settings.height))
                    dungeon[getCoordinateIndex(settings.width, rx, ry)] = groundBiome;
            }

            if (rooms.length > 0)
            {
                int x1 = clamp(newRoom.centerX(), newRoom.x + 1, newRoom.x + newRoom.w - 2);
                int y1 = clamp(newRoom.centerY(), newRoom.y + 1, newRoom.y + newRoom.h - 2);
                int x2 = clamp(closest.centerX(), closest.x + 1, closest.x + closest.w - 2);
                int y2 = clamp(closest.centerY(), closest.y + 1, closest.y + closest.h - 2);

                if (uniform(0, 2, rnd) == 0)
                {
                    foreach (cx; min(x1, x2) .. max(x1, x2) + 1)
                        if (isInBounds(cx, y1, settings.width, settings.height))
                            dungeon[getCoordinateIndex(settings.width, cx, y1)] = groundBiome;

                    foreach (cy; min(y1, y2) .. max(y1, y2) + 1)
                        if (isInBounds(x2, cy, settings.width, settings.height))
                            dungeon[getCoordinateIndex(settings.width, x2, cy)] = groundBiome;
                }
                else
                {
                    foreach (cy; min(y1, y2) .. max(y1, y2) + 1)
                        if (isInBounds(x1, cy, settings.width, settings.height))
                            dungeon[getCoordinateIndex(settings.width, x1, cy)] = groundBiome;

                    foreach (cx; min(x1, x2) .. max(x1, x2) + 1)
                        if (isInBounds(cx, y2, settings.width, settings.height))
                            dungeon[getCoordinateIndex(settings.width, cx, y2)] = groundBiome;
                }
            }

            rooms ~= newRoom;
            roomsCreated++;
        }
    }

    foreach (y; 1 .. settings.height - 1)
    foreach (x; 1 .. settings.width - 1)
    {
        int idx = getCoordinateIndex(settings.width, x, y);
        if (dungeon[idx] == Biome.none)
        {
            bool adjacentToFloor = false;
            foreach (ny; y-1 .. y+2)
            foreach (nx; x-1 .. x+2)
            {
                if (nx == x && ny == y) continue;
                int nIdx = getCoordinateIndex(settings.width, nx, ny);
                if (dungeon[nIdx] == groundBiome)
                {
                    adjacentToFloor = true;
                    break;
                }
            }
            if (adjacentToFloor)
                dungeon[idx] = wallBiome;
        }
    }

    return dungeon;
}

/// Generates tiles based on the biome coordinate array given.
auto generateTiles(TBiome = Biome, TBiomeTileType = BiomeTileType)(MapSettings settings, TBiome[] biomes, int[] heights, BiomeTile!(TBiome, TBiomeTileType) delegate(int generatorValue, TBiome biome, int height) tileGenerator)
{
    auto tileMap = createCoordinateArray!(BiomeTile!(TBiome,TBiomeTileType))(settings.width, settings.height);

    foreach (y; 0 .. settings.height)
    {
        foreach (x; 0 .. settings.width)
        {
            int generatorValue = uniform(0,100, settings.random);
            int index = getCoordinateIndex(settings.width, x, y);
            auto biome = biomes[index];
            auto height = heights[index];

            tileMap[index] = tileGenerator(generatorValue, biome, height);
        }
    }

    return tileMap;
}

/// Generates water biome within an existing biome coordinate array.
void generateWaterBiome(TBiome = Biome)(MapSettings settings, TBiome[] biomes, TBiome waterType, bool delegate(TBiome biome) allowBiome, float waterThreshold  = 0.4, int noiseOffset = 1000)
{
    foreach (y; 0 .. settings.height)
    {
        foreach (x; 0 .. settings.width)
        {
            int index = getCoordinateIndex(settings.width, x, y);
            auto originalBiome = biomes[index];

            if (!allowBiome(originalBiome))
            {
                continue;
            }

            float noise = smoothNoise(cast(int)(x / settings.biomeSize), cast(int)(y / settings.biomeSize), settings.seed, noiseOffset);

            if (noise < waterThreshold)
            {
                biomes[index] = waterType;
            }
        }
    }
}

/// Generates a hill height coordinate array. Supply this array to generateTiles. For dungeons you may exclude this.
int[] generateHillHeights(MapSettings settings, int maxHeight = 3, int heightNormalization = 3, int noiseOffset = 2000)
{
    auto heightMap = createCoordinateArray!int(settings.width, settings.height);

    float minNoise = float.infinity;
    float maxNoise = -float.infinity;

    float[] rawNoise = new float[settings.width * settings.height];

    foreach (y; 0 .. settings.height)
    {
        foreach (x; 0 .. settings.width)
        {
            int index = getCoordinateIndex(settings.width, x, y);

            float noise = smoothNoise(
                cast(int)(x / settings.biomeSize),
                cast(int)(y / settings.biomeSize),
                settings.seed,
                noiseOffset
            );

            rawNoise[index] = noise;
            if (noise < minNoise) minNoise = noise;
            if (noise > maxNoise) maxNoise = noise;
        }
    }

    foreach (index, noise; rawNoise)
    {
        float normalized = (noise - minNoise) / (maxNoise - minNoise);
        float curved = normalized ^^ heightNormalization;
        int height = cast(int)(curved * (maxHeight + 1));
        heightMap[index] = clamp(height, 0, maxHeight);
    }

    return heightMap;
}

/// Generates rivers based on a given biome coordinate array.
void generateRivers(TBiome = Biome)(MapSettings settings, TBiome[] biomes, TBiome riverType, bool delegate(TBiome biome) allowBiome, int riverCount = 4, int maxLength = 500)
{
    void generateRiver(TBiome = Biome)(MapSettings settings, TBiome[] biomes, TBiome riverType, bool delegate(TBiome biome) allowBiome, int maxLength = 500, int startX = -1, int startY = 0)
    {
        Random rnd = Random(settings.seed + 9999);

        if (startX == -1)
            startX = uniform(0, settings.width, rnd);

        int x = startX;
        int y = startY;

        for (int i = 0; i < maxLength; ++i)
        {
            if (x < 0 || x >= settings.width || y < 0 || y >= settings.height)
                break;

            int index = getCoordinateIndex(settings.width, x, y);
            if (allowBiome(biomes[index]))
                biomes[index] = riverType;

            int dx = uniform(-1, 2, rnd);
            int dy = uniform(0, 2, rnd);

            x += dx;
            y += dy;

            int riverRadius = 2;

            foreach (oy; -riverRadius .. riverRadius + 1)
            foreach (ox; -riverRadius .. riverRadius + 1)
            {
                int nx = x + ox;
                int ny = y + oy;
                if (nx >= 0 && nx < settings.width && ny >= 0 && ny < settings.height)
                {
                    int nIndex = getCoordinateIndex(settings.width, nx, ny);
                    if (allowBiome(biomes[nIndex]))
                        biomes[nIndex] = riverType;
                }
            }
        }
    }

    Random rnd = Random(settings.seed + 666);

    foreach (i; 0 .. riverCount)
    {
        int startEdge = uniform(0, 4, rnd);
        int startX, startY;

        final switch (startEdge)
        {
            case 0: startX = uniform(0, settings.width, rnd); startY = 0; break;              // Top
            case 1: startX = uniform(0, settings.width, rnd); startY = settings.height - 1; break; // Bottom
            case 2: startX = 0; startY = uniform(0, settings.height, rnd); break;             // Left
            case 3: startX = settings.width - 1; startY = uniform(0, settings.height, rnd); break; // Right
        }

        generateRiver!TBiome(settings, biomes, riverType, allowBiome, maxLength, startX, startY);
    }
}

/// default tile generator based on the generic tile enum. Use this if you don't customize enum types and/or is fine with how biomes are created.
BiomeTile!(Biome, BiomeTileType) defaultTileGenerator(int generatorValue, Biome biome)
{
    alias BiomeTileStruct = BiomeTile!(Biome, BiomeTileType);
    
    final switch (biome)
    {
        case Biome.wall: return BiomeTileStruct(biome, BiomeTileType.wall);

        case Biome.water: return BiomeTileStruct(biome, BiomeTileType.water);
        case Biome.dirtyWater: return BiomeTileStruct(biome, BiomeTileType.dirtyWater);
        case Biome.ice: return BiomeTileStruct(biome, BiomeTileType.ice);
        case Biome.lava: return BiomeTileStruct(biome, BiomeTileType.lava);

        case Biome.plain:
            if (generatorValue < 3) return BiomeTileStruct(biome, BiomeTileType.grass, BiomeTileType.rock);
            else if (generatorValue < 6) return BiomeTileStruct(biome, BiomeTileType.grass, BiomeTileType.plant);
            else if (generatorValue < 10) return BiomeTileStruct(biome, BiomeTileType.grass, BiomeTileType.flower);
            else if (generatorValue < 95) return BiomeTileStruct(biome, BiomeTileType.grass);
            else return BiomeTileStruct(biome, BiomeTileType.grass, BiomeTileType.tree);

        case Biome.forest:
            if (generatorValue < 3) return BiomeTileStruct(biome, BiomeTileType.darkGrass, BiomeTileType.rock);
            else if (generatorValue < 6) return BiomeTileStruct(biome, BiomeTileType.darkGrass, BiomeTileType.plant);
            else if (generatorValue < 10) return BiomeTileStruct(biome, BiomeTileType.darkGrass, BiomeTileType.flower);
            else if (generatorValue < 84) return BiomeTileStruct(biome, BiomeTileType.darkGrass);
            else return BiomeTileStruct(biome, BiomeTileType.darkGrass, BiomeTileType.tree);

        case Biome.meadow:
            if (generatorValue < 3) return BiomeTileStruct(biome, BiomeTileType.grass, BiomeTileType.rock);
            else if (generatorValue < 6) return BiomeTileStruct(biome, BiomeTileType.grass, BiomeTileType.plant);
            else if (generatorValue < 10) return BiomeTileStruct(biome, BiomeTileType.grass, BiomeTileType.tree);
            else if (generatorValue < 65) return BiomeTileStruct(biome, BiomeTileType.grass);
            else return BiomeTileStruct(biome, BiomeTileType.grass, BiomeTileType.flower);

        case Biome.shrubland:
            if (generatorValue < 3) return BiomeTileStruct(biome, BiomeTileType.dirt, BiomeTileType.rock);
            else if (generatorValue < 6) return BiomeTileStruct(biome, BiomeTileType.dirt, BiomeTileType.tree);
            else if (generatorValue < 10) return BiomeTileStruct(biome, BiomeTileType.dirt, BiomeTileType.flower);
            else if (generatorValue < 95) return BiomeTileStruct(biome, BiomeTileType.dirt);
            else return BiomeTileStruct(biome, BiomeTileType.dirt, BiomeTileType.plant);

        case Biome.desert:
            if (generatorValue < 3) return BiomeTileStruct(biome, BiomeTileType.sand, BiomeTileType.rock);
            else if (generatorValue < 6) return BiomeTileStruct(biome, BiomeTileType.sand, BiomeTileType.plant);
            else if (generatorValue < 10) return BiomeTileStruct(biome, BiomeTileType.sand, BiomeTileType.flower);
            else if (generatorValue < 95) return BiomeTileStruct(biome, BiomeTileType.sand);
            else return BiomeTileStruct(biome, BiomeTileType.sand, BiomeTileType.tree);

        case Biome.snow:
            if (generatorValue < 3) return BiomeTileStruct(biome, BiomeTileType.snow, BiomeTileType.rock);
            else if (generatorValue < 6) return BiomeTileStruct(biome, BiomeTileType.snow, BiomeTileType.plant);
            else if (generatorValue < 10) return BiomeTileStruct(biome, BiomeTileType.snow, BiomeTileType.flower);
            else if (generatorValue < 95) return BiomeTileStruct(biome, BiomeTileType.snow);
            else return BiomeTileStruct(biome, BiomeTileType.snow, BiomeTileType.tree);

        case Biome.swamp:
            if (generatorValue < 3) return BiomeTileStruct(biome, BiomeTileType.dirtyGrass, BiomeTileType.rock);
            else if (generatorValue < 6) return BiomeTileStruct(biome, BiomeTileType.dirtyGrass, BiomeTileType.plant);
            else if (generatorValue < 10) return BiomeTileStruct(biome, BiomeTileType.dirtyGrass, BiomeTileType.flower);
            else if (generatorValue < 95) return BiomeTileStruct(biome, BiomeTileType.dirtyGrass);
            else return BiomeTileStruct(biome, BiomeTileType.dirtyGrass, BiomeTileType.tree);

        case Biome.deadland:
            if (generatorValue < 5) return BiomeTileStruct(biome, BiomeTileType.deadGround, BiomeTileType.rock);
            else if (generatorValue < 10) return BiomeTileStruct(biome, BiomeTileType.deadGround, BiomeTileType.plant);
            else if (generatorValue < 95) return BiomeTileStruct(biome, BiomeTileType.deadGround);
            else return BiomeTileStruct(biome, BiomeTileType.deadGround, BiomeTileType.tree);

        case Biome.jungle:
            if (generatorValue < 5) return BiomeTileStruct(biome, BiomeTileType.darkGrass, BiomeTileType.rock);
            else if (generatorValue < 14) return BiomeTileStruct(biome, BiomeTileType.darkGrass, BiomeTileType.plant);
            else if (generatorValue < 20) return BiomeTileStruct(biome, BiomeTileType.darkGrass, BiomeTileType.flower);
            else if (generatorValue < 84) return BiomeTileStruct(biome, BiomeTileType.darkGrass);
            else return BiomeTileStruct(biome, BiomeTileType.darkGrass, BiomeTileType.tree);

        case Biome.savanna:
            if (generatorValue < 3) return BiomeTileStruct(biome, BiomeTileType.savannaGrass, BiomeTileType.rock);
            else if (generatorValue < 6) return BiomeTileStruct(biome, BiomeTileType.savannaGrass, BiomeTileType.plant);
            else if (generatorValue < 10) return BiomeTileStruct(biome, BiomeTileType.savannaGrass, BiomeTileType.flower);
            else if (generatorValue < 95) return BiomeTileStruct(biome, BiomeTileType.savannaGrass);
            else return BiomeTileStruct(biome, BiomeTileType.savannaGrass, BiomeTileType.tree);

        case Biome.hell:
            if (generatorValue < 10) return BiomeTileStruct(biome, BiomeTileType.obsidian, BiomeTileType.rock);
            else if (generatorValue < 20) return BiomeTileStruct(biome, BiomeTileType.obsidian, BiomeTileType.tree);
            else return BiomeTileStruct(biome, BiomeTileType.obsidian);

        case Biome.none: return BiomeTileStruct(biome, BiomeTileType.none);
    }
}