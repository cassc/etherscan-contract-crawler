// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/Base64.sol";

// @author mande.eth
contract POCKETBLOCKS is ERC1155, Ownable {
  string public constant name = "POCKETBLOCKS";
  string public constant symbol = "PB";

  string[2][] private _items;

  string private constant _name1 = '{"name": "';
  string private constant _imag1 = '", "image": "data:image/svg+xml;base64,';
  string private constant _imag2 = '"}';

  constructor() ERC1155(""){}

  function uri(uint256 tokenId_) public view virtual override returns(string memory){
    string memory tokenName = _items[tokenId_ - 1][0];
    string memory tokenSVG = Base64.encode(bytes(_items[tokenId_ - 1][1]));
    string memory encodedJson = Base64.encode(abi.encodePacked(_name1, tokenName, _imag1, tokenSVG, _imag2));

    return string(abi.encodePacked("data:application/json;base64,", encodedJson));
  }

  function create(string calldata svg_, string calldata name_, uint256 editions_) external onlyOwner {
    _items.push([name_, svg_]);
    _mint(msg.sender, _items.length, editions_, "");
  }

  // Emergency
  function update(uint256 tokenId_, string calldata name_, string calldata svg_) external onlyOwner {
    _items[tokenId_ - 1] = [name_, svg_];
  }
}