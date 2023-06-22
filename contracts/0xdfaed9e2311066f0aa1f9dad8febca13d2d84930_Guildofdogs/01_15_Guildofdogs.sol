// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Guildofdogs is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    
    string public baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0.05 ether;
    uint256 public maxSupply = 6666;
    uint256 public initialSupply = 666;
    uint256 public maxMintAmount = 6;
    mapping(address => bool) public ifMinted;
    bool public ifPaused = true;



    constructor() ERC721("Guildofdogs", "GOD") {
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(uint numberOfTokens) public payable nonReentrant {
        uint256 index = totalSupply();
        require(ifPaused == false,"Event not started");
        require(ifMinted[msg.sender] == false,"You have already minted");
        require(numberOfTokens > 0 && numberOfTokens <= maxMintAmount, "Exceeded max token purchase");
        require(index + numberOfTokens <= initialSupply, "Insufficient token supply, NFTs sold out");
        require(msg.value >= cost * numberOfTokens, "Insufficient funds!");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, index + i);
        }

        ifMinted[msg.sender] = true;
    }

    function mintTo(uint256 start, uint256 n, address receiver) public onlyOwner {
        require(start + n <= maxSupply, "Insufficient token supply");
        for (uint256 i = 0; i < n; i++) {
            _safeMint(receiver, start + i);
        }
    }

    function _unpause() public onlyOwner {
        ifPaused = false;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}