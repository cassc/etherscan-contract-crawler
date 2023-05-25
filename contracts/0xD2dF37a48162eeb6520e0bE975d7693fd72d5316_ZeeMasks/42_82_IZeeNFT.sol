// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

interface IZeeNFT {
    /// @notice Mint specific amount of tokens for a user.
    function mint(address receiver, uint256 quantity) external;

    /// @notice Burn a specific token ID.
    function burn(uint256 tokenId) external;
}