// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./Base64.sol";
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

contract PooPooShitTest is ERC721A, Ownable {
    uint256 public MAX_SUPPLY = 100000;

    constructor() ERC721A("PooPooShitTest", "TESTER") Ownable() {}

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory metaName = "PooPooShitTest";
        string memory metaDescription = "PooPooShitTest";
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                metaName,
                                '", "description":"',
                                metaDescription,
                                '", "image": "',
                                "ipfs://bafkreiexzwhjurxnop2ldfc5rirolxncmclkoju65bnmhylulhqf7f6wwu",
                                "}"
                            )
                        )
                    )
                )
            );
    }

    function mintBigChungusQTPieOnly(uint256 amount)
        external
        payable
        onlyOwner
    {
        require(totalSupply() < MAX_SUPPLY, "Mint already completed");
        _mint(msg.sender, amount);
    }
}