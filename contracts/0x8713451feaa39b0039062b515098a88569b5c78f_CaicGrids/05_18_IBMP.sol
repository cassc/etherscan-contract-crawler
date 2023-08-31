// SPDX-License-Identifier: MIT
// Copyright 2021 Arran Schlosberg / Twitter @divergence_art
pragma solidity >=0.8.0 <0.9.0;


/// @title IBMP interface
/// @dev interface of BMP.sol originally used in brotchain (0xd31fc221d2b0e0321c43e9f6824b26ebfff01d7d)
interface IBMP {

    /// @notice Returns an 8-bit grayscale palette for bitmap images.
    function grayscale() external pure returns (bytes memory);

    /// @notice Returns an 8-bit BMP encoding of the pixels.
    /// @param pixels bytes array of pixels
    /// @param width -
    /// @param height -
    /// @param palette bytes array
    function bmp(bytes memory pixels, uint32 width, uint32 height, bytes memory palette)
    external
    pure
    returns (bytes memory);
    
    /// @notice Returns the buffer, presumably from bmp(), as a base64 data URI.
    /// @param bmpBuf encoded bytes of pixels
    function bmpDataURI(bytes memory bmpBuf) external pure returns (string memory);

    /// @notice Scale pixels by repetition along both axes.
    /// @param pixels bytes array of pixels
    /// @param width -
    /// @param height -
    /// @param scale -
    function scalePixels(bytes memory pixels, uint32 width, uint32 height, uint32 scale)
    external
    pure
    returns (bytes memory);
}