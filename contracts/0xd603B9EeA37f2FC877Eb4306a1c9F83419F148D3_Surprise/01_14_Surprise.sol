// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC721Opensea.sol";

contract Surprise is ERC721Opensea {
    constructor() ERC721("Surprise, Surprise", "KARA-SURP") {}

    function gift(address[] calldata receivers) external onlyOwner {
        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], totalSupply() + 1);
        }
    }
}