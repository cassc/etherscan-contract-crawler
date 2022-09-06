// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface IRenderer {
    function render(
        uint256 tokenId,
        address underlyingTokenContract,
        uint256 underlyingTokenId,
        string calldata underlyingTokenURI,
        bool ownsUnderlying
    )
        external
        pure
        returns (string memory html);
}