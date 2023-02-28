// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';

abstract contract ERC1155SupplyWithAll is ERC1155 {
  mapping(uint256 => uint256) private _totalSupply;
  uint256 private _totalSupplyAll;

  function totalSupply(uint256 id) public view virtual returns (uint256) {
    return _totalSupply[id];
  }

  function totalSupply() public view virtual returns (uint256) {
    return _totalSupplyAll;
  }

  function exists(uint256 id) public view virtual returns (bool) {
    return totalSupply(id) > 0;
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

    if (from == address(0)) {
      for (uint256 i = 0; i < ids.length; ++i) {
        _totalSupply[ids[i]] += amounts[i];
        _totalSupplyAll += amounts[i];
      }
    }

    if (to == address(0)) {
      for (uint256 i = 0; i < ids.length; ++i) {
        _totalSupply[ids[i]] -= amounts[i];
        _totalSupplyAll -= amounts[i];
      }
    }
  }
}