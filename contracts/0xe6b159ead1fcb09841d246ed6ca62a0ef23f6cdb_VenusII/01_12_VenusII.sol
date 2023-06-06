//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VenusII is ERC721, Ownable {
    uint public constant MAX_EDITIONS = 1500;
    uint public TOTAL_SUPPLY = 0;
    string public TOKEN_URI;

    constructor(string memory uri) ERC721("Venus II", "VNSII") {
        TOKEN_URI = uri;
    }

    /**
     * @dev Mints a token to a specified address, can only be called by the owner
     * @param to address to mint the token to
     */
    function mint(address to) public onlyOwner {
        require(TOTAL_SUPPLY < MAX_EDITIONS, "Allocation Exhausted: MAX_EDITIONS reached");
        _safeMint(to, TOTAL_SUPPLY);
        TOTAL_SUPPLY += 1;
    }

    /**
     * @dev Mints a token to a specified address
     */
    function setTokenURI(string memory uri) public onlyOwner {
        TOKEN_URI = uri;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return TOKEN_URI;
    }
}