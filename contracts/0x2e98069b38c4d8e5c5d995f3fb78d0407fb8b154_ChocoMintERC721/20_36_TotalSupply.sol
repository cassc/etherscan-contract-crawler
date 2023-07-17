// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

abstract contract TotalSupply is ERC721Upgradeable {
  uint256 private _totalSupply;

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function _mint(address to, uint256 tokenId) internal virtual override {
    super._mint(to, tokenId);
    _totalSupply++;
  }

  function _burn(uint256 tokenId) internal virtual override {
    super._burn(tokenId);
    _totalSupply--;
  }

  // solhint-disable-next-line ordering
  uint256[50] private __gap;
}