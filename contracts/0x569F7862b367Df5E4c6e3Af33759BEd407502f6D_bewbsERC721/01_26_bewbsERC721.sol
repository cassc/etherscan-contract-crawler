// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
__/\\\\\\\\\\\\\_____________________________________/\\\_____________________        
 _\/\\\/////////\\\__________________________________\/\\\_____________________       
  _\/\\\_______\/\\\__________________________________\/\\\_____________________      
   _\/\\\\\\\\\\\\\\______/\\\\\\\\___/\\____/\\___/\\_\/\\\_________/\\\\\\\\\\_     
    _\/\\\/////////\\\___/\\\/////\\\_\/\\\__/\\\\_/\\\_\/\\\\\\\\\__\/\\\//////__    
     _\/\\\_______\/\\\__/\\\\\\\\\\\__\//\\\/\\\\\/\\\__\/\\\////\\\_\/\\\\\\\\\\_   
      _\/\\\_______\/\\\_\//\\///////____\//\\\\\/\\\\\___\/\\\__\/\\\_\////////\\\_  
       _\/\\\\\\\\\\\\\/___\//\\\\\\\\\\___\//\\\\//\\\____\/\\\\\\\\\___/\\\\\\\\\\_ 
        _\/////////////______\//////////_____\///__\///_____\/////////___\//////////__
 */
/// @author: bewbs.fans

import "@manifoldxyz/creator-core-solidity/contracts/ERC721Creator.sol";

contract bewbsERC721 is ERC721Creator {
    uint256 private _tokenCounter = 1;
    uint256 private _maxSupply = 8008;
    uint256 private _reserved = 69;
    uint256 private _price = 0.08 ether;

    constructor() ERC721Creator("bewbs", "BWBS") {}

    function mint(uint256 num) public payable {
        uint256 supply = _tokenCounter; // totalSupplyBase();
        require(num < 8, "You can mint a maximum of 8 bewbs");
        require(
            supply + num <= _maxSupply - _reserved,
            "Exceeds maximum bewbs supply"
        );
        require(msg.value >= _price * num, "Ether sent is not correct");

        for (uint256 i; i < num; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }

    function getPrice() public view returns (uint256) {
        return _price;
    }

    function giveAway(address _to, uint256 _amount) external adminRequired {
        require(_amount <= _reserved, "Exceeds reserved bewbs supply");

        uint256 supply = _tokenCounter; // totalSupply();
        for (uint256 i; i < _amount; i++) {
            _safeMint(_to, supply + i);
        }

        _reserved -= _amount;
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}