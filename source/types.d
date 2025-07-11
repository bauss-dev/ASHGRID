/**
* Copyright © ASHGRID 2025
* License: MIT (https://github.com/bauss-dev/ASHGRID/blob/main/LICENSE)
* Author: Jacob Jensen (bauss-dev)
*/
module ashgrid.types;

import std.random : Random;

import ashgrid.enums;
import ashgrid.functions : smoothNoise;

/// The map settings for the procedural map generator.
public final class MapSettings
{
    private:
    /// The seed.
    uint _seed;
    /// The width.
    int _width;
    /// The height.
    int _height;
    /// The biome size.
    float _biomeSize;

    public:
    /// Creates a new map settings. biomeSize defaults to 20f.
    this(uint seed, int width, int height, float biomeSize = 20f)
    {
        _seed = seed;
        _width = width;
        _height = height;
        _biomeSize = biomeSize;

        this.random = Random(seed);

        this.noiseFunction = (x,y,s,o) => smoothNoise(x,y,s,o);
    }

    float delegate(int x, int y, uint seed, int offset) noiseFunction;

    package(ashgrid)
    {
        /// The random generator.
        Random random;
    }

    @property
    {
        /// Gets the seed.
        uint seed() { return _seed; }

        /// Gets the width.
        int width() { return _width; }

        /// Gets the height.
        int height() { return _height; }

        /// Gets the biome size.
        float biomeSize() { return _biomeSize; }
    }
}

/// The biome tile struct. Represents a given tile.
public struct BiomeTile(TBiome = Biome, TBiomeTileType = BiomeTileType)
{
    /// The biome it was represented in.
    TBiome biome;
    /// the base type. Ex. grass
    BiomeTileType baseType;
    /// The secondary type. Ex. tree/plant - generally none
    BiomeTileType secondaryType;
    /// The height.
    int height;
    /// The piece to render.
    Piece piece;

    /// Creates a new biome tile.
    this(TBiome biome, BiomeTileType baseType)
    {
        this.biome = biome;
        this.baseType = baseType;
        this.secondaryType = BiomeTileType.none;
        this.height = 0;
        this.piece = Piece.center;
    }

    /// Creates a new biome tile.
    this(TBiome biome, BiomeTileType baseType, BiomeTileType secondaryType)
    {
        this.biome = biome;
        this.baseType = baseType;
        this.secondaryType = secondaryType;
        this.height = 0;
        this.piece = Piece.center;
    }
}
