// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract RanERC721Mock is ERC721 {
    constructor (string memory name, string memory symbol) ERC721 (name, symbol) public {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}