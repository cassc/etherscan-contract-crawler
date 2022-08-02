// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ChibiJersey is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI;

    constructor() ERC721("Chibi Dinos Jersey", "ChibiJersey") {}

    // ONLY OWNER
    function gift(address[] calldata recipients) external onlyOwner {
        uint256 _supply = totalSupply();
        // zero-index i for recipients array
        for (uint256 i = 0; i < recipients.length; i++) {
            _safeMint(recipients[i], _supply + i + 1); // increment by 1 for token IDs
        }
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        baseURI = URI;
    }

    // PUBLIC
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }
}