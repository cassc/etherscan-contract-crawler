// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Sweep is ERC721 {
    uint256 private _tokenCounter;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    function batchMint(uint256 _numTokens) external {
        uint256 _tokenId;
        for (uint256 i = 0; i < _numTokens; i++) {
            _tokenId = _tokenCounter;
            _safeMint(msg.sender, _tokenId);
            _tokenCounter++;
        }
    }
}