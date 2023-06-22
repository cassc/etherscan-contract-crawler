// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC165.sol";

contract ERC721Metadata is Ownable, ERC165 {
  bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
  string private _baseTokenURI;
  string private _NFTName = "AsciiPunks";
  string private _NFTSymbol = "ASC";

  constructor() {
    _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    _baseTokenURI = "https://api.asciipunks.com/punks/";
  }

  function name() external view returns (string memory) {
    return _NFTName;
  }

  function symbol() external view returns (string memory) {
    return _NFTSymbol;
  }

  function setBaseURI(string calldata newBaseTokenURI) public onlyOwner {
    _baseTokenURI = newBaseTokenURI;
  }

  function baseURI() public view returns (string memory) {
    return _baseURI();
  }

  function _baseURI() internal view returns (string memory) {
    return _baseTokenURI;
  }
}