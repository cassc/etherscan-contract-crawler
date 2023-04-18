// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TheG is ERC721, ERC721Enumerable, Ownable {
    uint256 private _tokenIdCounter;
    string private _baseTokenURI;
    uint256 public constant MAX_SUPPLY = 50;

    constructor() ERC721("The G House", "TheGHouse") {
        _tokenIdCounter = 0;
    }

    function mintNFT(address to) public onlyOwner {
        require(_tokenIdCounter < MAX_SUPPLY, "Minting would exceed max supply");
        _safeMint(to, _tokenIdCounter);
        _tokenIdCounter++;
    }

    function mintBatch(address to, uint256 numTokens) public onlyOwner {
        require(_tokenIdCounter + numTokens <= MAX_SUPPLY, "Minting would exceed max supply");
        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(to, _tokenIdCounter);
            _tokenIdCounter++;
        }
    }

    function setBaseTokenURI(string memory baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, "/"));
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory base = _baseURI();
        return
            bytes(base).length > 0
                ? string(
                    abi.encodePacked(base, Strings.toString(tokenId), ".json")
                )
                : "";
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(owner()).transfer(balance);
    }
}