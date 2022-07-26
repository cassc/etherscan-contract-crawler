// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./CrossChainERC721.sol";

contract NFT is CrossChainERC721 {
    constructor(
        string memory name_,
        string memory symbol_,
        address lzEndpoint_,
        uint256 lzGas_
    ) CrossChainERC721(name_, symbol_, lzEndpoint_, lzGas_) {}

    function mint(address account, uint256 tokenId) public {
        _safeMint(account, tokenId);
    }
}