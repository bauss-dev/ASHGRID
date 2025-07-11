# ASHGRID

ASHGRID is a procedural map generator written in D.

## Examples

### Initialization

```d
auto settings = new MapSettings(seed, width, height);
```

### Generating a map

```d
auto biomes = generateBiomes(settings,
[
    Biome.plain : 0.4f, // 405 plain
    Biome.forest : 0.4f, // 40% forest
    Biome.swamp :  0.2f // 20% swamp
]);

generateWaterBiome!Biome(settings, biomes,
    Biome.water,
    (b) => b == Biome.plain || b == Biome.forest);
generateWaterBiome!Biome(settings, biomes,
    Biome.dirtyWater,
    (b) => b == Biome.swamp);

generateRivers!Biome(settings, biomes,
    Biome.water,
    (b) => b == Biome.plain || b == Biome.forest);
generateRivers!Biome(settings, biomes,
    Biome.dirtyWater,
    (b) => b == Biome.swamp);

auto heights = generateHillHeights(settings);

auto biomeTiles = generateTiles!(Biome, BiomeTileType)(settings, biomes, heights, (g,b,h)
{
    auto tile = defaultTileGenerator(g,b);

    if (tile.baseType != BiomeTileType.water && tile.baseType != BiomeTileType.dirtyWater)
    {
        tile.height = h;
    }

    return tile;
});

smoothTileEdges!(Biome, BiomeTileType)(settings, biomeTiles, (t)
{
    return t.baseType == BiomeTileType.water || t.baseType == BiomeTileType.dirtyWater;
});
```

### Generating a dungeon

```d
auto biomes = generateDungeon!Biome(settings, Biome.none, Biome.wall, Biome.plain);

auto heights = createCoordinateArray!int(settings.width, settings.height);

auto biomeTiles = generateTiles!(Biome, BiomeTileType)(settings, biomes, heights, (g,b,h)
{
    auto tile = defaultTileGenerator(g,b);

    tile.height = h;

    return tile;
});
```

How you render everything is up to you and will depend on your game engine etc.

You may use the functions createCoordinateArray() and getCoordinateIndex() to interact with the final produced map.