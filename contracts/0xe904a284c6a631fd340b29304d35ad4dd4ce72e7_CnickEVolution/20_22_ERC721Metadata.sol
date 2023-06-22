// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

/**
 * @title ERC721B Burnable Token
 * @dev ERC721B Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Metadata is IERC721Metadata {
  string private _name;
  string private _symbol;

  /**
   * @dev Sets the name, symbol
   */
  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
  }

  /**
   * @dev See {IERC721Metadata-name}.
   */
  function name() public view virtual returns(string memory) {
    return _name;
  }

  /**
   * @dev See {IERC721Metadata-symbol}.
   */
  function symbol() public view virtual returns(string memory) {
    return _symbol;
  }
  
}