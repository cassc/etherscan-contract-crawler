// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

library ShackledStructs {
    struct Metadata {
        string colorScheme; /// name of the color scheme
        string geomSpec; /// name of the geometry specification
        uint256 nPrisms; /// number of prisms made
        string pseudoSymmetry; /// horizontal, vertical, diagonal
        string wireframe; /// enabled or disabled
        string inversion; /// enabled or disabled
    }

    struct RenderParams {
        uint256[3][] faces; /// index of verts and colorss used for each face (triangle)
        int256[3][] verts; /// x, y, z coordinates used in the geometry
        int256[3][] cols; /// colors of each vert
        int256[3] objPosition; /// position to place the object
        int256 objScale; /// scalar for the object
        int256[3][2] backgroundColor; /// color of the background (gradient)
        LightingParams lightingParams; /// parameters for the lighting
        bool perspCamera; /// true = perspective camera, false = orthographic
        bool backfaceCulling; /// whether to implement backface culling (saves gas!)
        bool invert; /// whether to invert colors in the final encoding stage
        bool wireframe; /// whether to only render edges
    }

    /// struct for testing lighting
    struct LightingParams {
        bool applyLighting; /// true = apply lighting, false = don't apply lighting
        int256 lightAmbiPower; /// power of the ambient light
        int256 lightDiffPower; /// power of the diffuse light
        int256 lightSpecPower; /// power of the specular light
        uint256 inverseShininess; /// shininess of the material
        int256[3] lightPos; /// position of the light
        int256[3] lightColSpec; /// color of the specular light
        int256[3] lightColDiff; /// color of the diffuse light
        int256[3] lightColAmbi; /// color of the ambient light
    }
}