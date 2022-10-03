// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface INFTsDividend {
    function distributeDividends(uint256 amount) external;

    function distributeLevelDividends(uint256 nftLevel, uint256 amount)
        external;

    function addTokenId(uint256 tokenId, uint256 nftLevel) external;

    function removeTokenId(uint256 tokenId, uint256 nftLevel) external;
}
