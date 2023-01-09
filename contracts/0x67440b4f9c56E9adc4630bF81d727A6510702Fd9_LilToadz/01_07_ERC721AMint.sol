// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract LilToadz is ERC721A, Ownable {
    uint256 MAX_MINTS = 2;
    uint256 MAX_SUPPLY = 2222;
    uint256 public mintRate = 0.002 ether;
    bool public paused = false;

    string public baseURI = "ipfs://bafybeiaes5tihug4ktwwtnwvxkkprmknkhnaotjmz4zm6e4xvfzv2sqjcy/";
    using Strings for uint256;

    constructor() ERC721A("LiL Toadz", "LiLTDZ") {}

    function mint(uint256 quantity) external payable {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(!paused, "Contract is paused");
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS, "Exceeded the limit");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        require(msg.value >= (mintRate * quantity), "Not enough ether sent");
        _safeMint(msg.sender, quantity);
    }


    function pause(bool _state) public onlyOwner {
        paused = _state;

    }  

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    string memory currentBaseURI = baseURI;
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
        : '';
  }
    
    function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

    function setMintRate(uint256 _mintRate) public onlyOwner {
        mintRate = _mintRate;
    }

}