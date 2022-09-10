// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TheQueensCorgis is ERC721A, Ownable {

    constructor() ERC721A("TheQueensCorgis", "QC") {
        }

    uint256 public maxMint = 1; 
    uint256 public maxSupply = 10000;   
    string public baseURI = "";
    bool public mintLive;
    
    struct History {
        uint64 minted;
    }
    mapping(address => History) public history;

    function mint(uint256 _mintAmount) public payable {
        require(mintLive, "Error - Mint Not Live");
        require(_mintAmount < maxMint + 1, "Error - TX Limit Exceeded");
        require(totalSupply() + _mintAmount < maxSupply + 1, "Error - Max Supply Exceeded");
        require(history[msg.sender].minted + _mintAmount < maxMint + 1,"Error - Wallet Already Minted");
        history[msg.sender].minted += uint64(_mintAmount);
        _safeMint(msg.sender, _mintAmount);
    }

    function _baseURI() internal view override(ERC721A) virtual returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function setMint(uint256 _maxMint) public onlyOwner {
        maxMint = _maxMint;
    }

    function toggleMinting() public onlyOwner {
      mintLive = !mintLive;
    }

}