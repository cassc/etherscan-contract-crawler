// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC165} from "../ext/IERC165.sol";
import {MoonImageConfig} from "../../moon/MoonStructs.sol";

/// @title AlienArtBase
/// @author Aspyn Palatnick (aspyn.eth, stuckinaboot.eth)
/// @notice Alien Art is an on-chain NFT composability standard for on-chain art and traits.
abstract contract AlienArtBase is IERC165 {
    // Define functions that alien art contracts can override. These intentionally
    // use function state mutability as view to allow for reading on-chain data.

    /// @notice get art name.
    /// @return art name.
    function getArtName() external view virtual returns (string memory);

    /// @notice get alien art image for a particular token.
    /// @param tokenId token id.
    /// @param moonSeed moon seed.
    /// @param moonImageConfig moon image config.
    /// @param rotationInDegrees rotation in degrees.
    /// @return alien art image.
    function getArt(
        uint256 tokenId,
        bytes32 moonSeed,
        MoonImageConfig calldata moonImageConfig,
        uint256 rotationInDegrees
    ) external view virtual returns (string memory);

    /// @notice get moon filter for a particular token.
    /// @param tokenId token id.
    /// @param moonSeed moon seed.
    /// @param moonImageConfig moon image config.
    /// @param rotationInDegrees rotation in degrees.
    /// @return moon filter.
    function getMoonFilter(
        uint256 tokenId,
        bytes32 moonSeed,
        MoonImageConfig calldata moonImageConfig,
        uint256 rotationInDegrees
    ) external view virtual returns (string memory) {
        return "";
    }

    /// @notice get alien art traits for a particular token.
    /// @param tokenId token id.
    /// @param moonSeed moon seed.
    /// @param moonImageConfig moon image config.
    /// @param rotationInDegrees rotation in degrees.
    /// @return alien art traits.
    function getTraits(
        uint256 tokenId,
        bytes32 moonSeed,
        MoonImageConfig calldata moonImageConfig,
        uint256 rotationInDegrees
    ) external view virtual returns (string memory) {
        return "";
    }
}