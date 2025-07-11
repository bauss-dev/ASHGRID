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
    wallBottom,
    door,
    floor,

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
    wallBottom,
    door,
    floor,

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

/// A tile piece based on where it's located in the tileset. Used for smoothing ex. water.
public enum Piece
{
    center,
    left,
    right,

    top,
    topLeft,
    topRight,

    bottom,
    bottomRight,
    bottomLeft,

    innerTopRight,
    innerTopLeft,
    innerBottomRight,
    innerBottomLeft
}
