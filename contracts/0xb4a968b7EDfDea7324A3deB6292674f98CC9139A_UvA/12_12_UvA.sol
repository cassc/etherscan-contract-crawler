// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UvA is ERC721, Ownable {
    using Strings for uint256;
    string private baseURI;

    constructor(string memory _baseURI) ERC721("Certificate of completion Research Master Information Law of the University of Amsterdam", "RMILUVA") {
        setBaseURI(_baseURI);
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURI, id.toString(), ".json"));
    }

    function approve(address to, uint256 tokenId) public virtual override {
        require(false, "approve function disabled");
    }

    function transferFrom(address from, address to, uint tokenId) public virtual override {
        require(msg.sender == owner(), "transfer can only be initiated by the contract owner");
        _transfer(from, to, tokenId);
    }

    function mintNFT(address to, uint tokenId) public onlyOwner {
        require(!_exists(tokenId), "NFT already exists");
        _safeMint(to, tokenId);
    }
}