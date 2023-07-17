// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

contract ERC721Template is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter public uid;

    constructor() ERC721("Fake NFT", "NFT") {}

    function mint(address to) public {
        uid.increment();
        _safeMint(to, uid.current());
    }

    function batchMint(address to, uint256 amount) public {
        for (uint256 i = 0; i < amount; i++) {
            uid.increment();
            _safeMint(to, uid.current());
        }
    }


}