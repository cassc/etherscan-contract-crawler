// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./LibERC721LazyMint.sol";

interface IMarketToken {
    function mint(
        address to,
        uint256 tokenId,
        string memory tokenHash
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFromOrMint(
        LibERC721LazyMint.Mint721Data memory data,
        address from,
        address to
    ) external;
}