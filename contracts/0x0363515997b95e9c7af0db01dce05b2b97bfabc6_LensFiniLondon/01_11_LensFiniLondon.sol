pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract LensFiniLondon is Ownable, ERC721 {
    uint256 private nextTokenId;
    string public baseURI = "https://api.finiliar.com/lens-fini-london/";

    constructor()
      ERC721("LensFiniLondon", "LFL")
    {}

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function adminMint(address to) external onlyOwner {
        _safeMint(to, nextTokenId++);
    }
}