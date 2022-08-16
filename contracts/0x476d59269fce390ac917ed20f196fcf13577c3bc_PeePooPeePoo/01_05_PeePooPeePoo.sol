// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@erc721a/ERC721A.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";

/*
    ░░░░░░░░░░░█▀▀░░█░░░░░░
    ░░░░░░▄▀▀▀▀░░░░░█▄▄░░░░
    ░░░░░░█░█░░░░░░░░░░▐░░░
    ░░░░░░▐▐░░░░░░░░░▄░▐░░░
    ░░░░░░█░░░░░░░░▄▀▀░▐░░░
    ░░░░▄▀░░░░░░░░▐░▄▄▀░░░░
    ░░▄▀░░░▐░░░░░█▄▀░▐░░░░░
    ░░█░░░▐░░░░░░░░▄░█░░░░░
    ░░░█▄░░▀▄░░░░▄▀▐░█░░░░░
    ░░░█▐▀▀▀░▀▀▀▀░░▐░█░░░░░
    ░░▐█▐▄░░▀░░░░░░▐░█▄▄░░░
    ░░░▀▀░▄QTPie▄░░▐▄▄▄▀░░░░
*/

contract PeePooPeePoo is ERC721A, Ownable {
    uint256 public MAX_PEEPOOPEEPOO = 100000;

    constructor() ERC721A("PeePooPeePoo", "PEEPOOPEEPOO") Ownable() {}

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            "ipfs://bafkreiexzwhjurxnop2ldfc5rirolxncmclkoju65bnmhylulhqf7f6wwu";
    }

    function mint() external payable onlyOwner {
        require(totalSupply() < MAX_PEEPOOPEEPOO, "Mint already completed");
        _mint(msg.sender, 5000);
    }
}