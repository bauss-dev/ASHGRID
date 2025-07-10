/**
* Copyright © ASHGRID 2025
* License: MIT (https://github.com/bauss-dev/ASHGRID/blob/main/LICENSE)
* Author: Jacob Jensen (bauss-dev)
*/
module ashgrid.enums;

/// Biome enum that includes possible basic biomes to generate.
public enum Biome
{
    none,

    wall,

    water,
    dirtyWater,
    ice,
    lava,

    plain,
    forest,
    meadow,
    shrubland,
    desert,
    snow,
    swamp,
    deadland,
    jungle,
    savanna,
    hell
}

/// Biome tile enum that includes possible basic tile types to generate.
public enum BiomeTileType
{
    none,

    wall,

    water,
    dirtyWater,
    lava,
    ice,

    grass,
    darkGrass,
    dirtyGrass,
    sand,
    snow,
    dirt,
    deadGround,
    savannaGrass,
    obsidian,

    tree,
    plant,
    flower,
    rock
}