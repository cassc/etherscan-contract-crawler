// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./standards/ERC721G.sol";

contract TheKoreans1945 is ERC721G {
    constructor() ERC721G("The Koreans", "KOREANS", "https://storage.googleapis.com/webplusone/thekoreans/metadata/") {}

    function _mint(address to, uint256 tokenId) internal override {
        require(_totalSupply < 1945, "ALL_TOKEN_MINTED");
        super._mint(to, tokenId);
    }

    function _mintBatch(address to, uint256[] calldata tokenIds) internal override {
        require(_totalSupply + tokenIds.length <= 1945, "ALL_TOKEN_MINTED");
        super._mintBatch(to, tokenIds);
    }

    function burn(uint256) external override {
        revert("UNAVAILABLE");
    }

    function burnBatch(address, uint256[] calldata) external override {
        revert("UNAVAILABLE");
    }
}