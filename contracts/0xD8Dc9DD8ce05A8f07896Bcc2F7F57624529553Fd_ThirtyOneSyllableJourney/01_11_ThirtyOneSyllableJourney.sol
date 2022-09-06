// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/[email protected]/token/ERC721/ERC721.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract ThirtyOneSyllableJourney is ERC721, Ownable {
    constructor() ERC721("ThirtyOneSyllableJourney", "TOSJ") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.io/ipfs/QmUcUzvZQ1m1AUNpras33biDwS9PcSxeTfVRr3no7SxAVU/";
    }

    function safeMint(uint256 tokenId) public onlyOwner {
        _safeMint(msg.sender, tokenId);
    }

    function safeMultipleMint(uint256 mintCount) public onlyOwner {
        for (uint256 id = 1; id <= mintCount; id++){
        safeMint(id);
    }
    }
}