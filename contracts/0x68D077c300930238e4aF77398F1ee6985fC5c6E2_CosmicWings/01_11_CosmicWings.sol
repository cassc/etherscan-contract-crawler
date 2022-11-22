// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact [email protected]
contract CosmicWings is ERC721, Ownable {
    constructor() ERC721("CosmicWings", "COWI") {}

    function tokenURI(uint256 tokenId)
        public
        pure
        override
        returns (string memory)
    {
        require(
            tokenId == 1,
            "This contract has only one valid ID and it's 1."
        );
        return "ipfs://QmRcaBhWRJiw6RmtHFTTL6r1T9JiJAYNamHwh1wEx1vZ7s";
    }

    function safeMint(address to) public onlyOwner {
        _safeMint(to, 1);
    }
}