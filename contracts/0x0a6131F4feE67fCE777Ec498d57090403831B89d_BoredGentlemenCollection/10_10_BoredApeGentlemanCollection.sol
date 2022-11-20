// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BoredGentlemenCollection is ERC1155, Ownable {
  string public name;
  string public symbol;
  uint256 public totalSupply;


  mapping(uint256 => string) public tokenURI;

  constructor() ERC1155("") {
    name = "Bored Gentlemen Collection";
    symbol = "BGC";
  }

  function mint(uint256 _amount, uint256 _tokenId) external onlyOwner {
    _mint(msg.sender, _tokenId, _amount, "");
    totalSupply = totalSupply + _amount;
  }

  function setURI(uint256 _id, string memory _uri) external onlyOwner {
    tokenURI[_id] = _uri;
    emit URI(_uri, _id);
  }

  function uri(uint256 _id) public view override returns (string memory) {
    return tokenURI[_id];
  }
}