// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Haymarket is ERC1155 {
    uint256 public constant PURPLE = 0;
    uint256 public constant SILVER = 1;
    uint256 public constant GOLD = 2;
    uint256 public constant MULTICOLOR = 3;

    string public name = "Haymarket NFT";
    string public symbol = "HMN";

    constructor() ERC1155 ("") {
        _mint(msg.sender, PURPLE, 300, "");
        _mint(msg.sender, SILVER, 150, "");
        _mint(msg.sender, GOLD, 100, "");
        _mint(msg.sender, MULTICOLOR, 50, "");
    }

    function uri(uint256 _id) public view virtual override returns (string memory) {
        if(_id == PURPLE) 
        return "https://haymarket-nft.s3.us-west-2.amazonaws.com/hay-jsons/Purple.json";
        else if (_id == SILVER)
        return "https://haymarket-nft.s3.us-west-2.amazonaws.com/hay-jsons/Silver.json";
        else if (_id ==  GOLD)
        return "https://haymarket-nft.s3.us-west-2.amazonaws.com/hay-jsons/Gold.json";
        else if (_id == MULTICOLOR)
        return "https://haymarket-nft.s3.us-west-2.amazonaws.com/hay-jsons/Multicolor.json";
        else return "";
    }
}