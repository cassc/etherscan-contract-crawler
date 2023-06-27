// SPDX-License-Identifier: MIT

pragma solidity >=0.5.8 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract LOM_STELLA is Ownable, ERC721, ReentrancyGuard {
    string private baseURI;

    constructor() ERC721("LOM STELLA", "STELLA") {}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public nonReentrant onlyOwner {
        baseURI = _newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Invalid tokenId.");
        return string(abi.encodePacked(ERC721.tokenURI(tokenId), ".json"));
    }

    function mint(address to, uint256 tokenId) external onlyOwner {
        require(!_exists(tokenId), "This token has already been minted.");
        _safeMint(to, tokenId);
    }
}