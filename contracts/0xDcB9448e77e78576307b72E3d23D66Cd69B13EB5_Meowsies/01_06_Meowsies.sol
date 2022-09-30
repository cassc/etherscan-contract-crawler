// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Meowsies is ERC721A, Ownable {
    //maximum number of NFTs in the collection
    uint256 public MAX_SUPPLY = 800;

    //the price for each NFT
    uint256 private _mintPrice = 0.005 ether;
    //pre-reveal base URI (will change value by calling setBaseURI manually when ready to reveal)
    string private _baseTokenURI = "";

    constructor() ERC721A("Meowsies", "MWSY") {}

    function mint(uint256 quantity) external payable {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        require(msg.value >= (_mintPrice * quantity), "Not enough ether sent");
        _safeMint(msg.sender, quantity);
    }

    function setMintPrice(uint256 mintPrice) external onlyOwner {
        _mintPrice = mintPrice;
    }

    function getMintPrice() external view returns (uint256) {
        return _mintPrice;
    }

    function setMaxSupply(uint256 maxSupply) external onlyOwner {
        require(maxSupply < MAX_SUPPLY, "Can only reduce collection size.");
        MAX_SUPPLY = maxSupply;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), '.json')) : '';
    }
}