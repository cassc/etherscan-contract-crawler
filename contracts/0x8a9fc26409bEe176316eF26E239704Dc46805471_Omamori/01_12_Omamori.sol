// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Omamori is ERC721A, Ownable {
    uint256 public immutable cost = 0.006 ether;
    uint32 public immutable maxMint = 6;
    uint32 public immutable MAXSUPPLY = 7777;
    bool public started = false;
    mapping(address => bool) public freeClaimed;
    string  public baseURI;

    constructor()
    ERC721A ("Omamori", "OM") {
        _safeMint(msg.sender, 1);
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 0;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function mint(uint32 amount) public payable {
        require(tx.origin == msg.sender, "pls don't use contract call");
        require(started,"not yet started");
        require(totalSupply() + amount <= MAXSUPPLY,"sold out");
        require(amount <= maxMint,"max 6 amount");
        if(freeClaimed[msg.sender])
        {
            require(msg.value >= amount * cost,"insufficient");
        }
        else 
        {
            freeClaimed[msg.sender] = true;
            require(msg.value >= (amount-1) * cost,"insufficient");
        }
        _safeMint(msg.sender, amount);
    }

    function enableMint(bool mintStarted) external onlyOwner {
      started = mintStarted;
    }

    function getMintedFree(address addr) public view returns (bool){
        return freeClaimed[addr];
    }

    function withdraw() public onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "failed");
    }
}