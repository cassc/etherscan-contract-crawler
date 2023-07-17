// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

abstract contract DefaultApproval is ERC721Upgradeable {
  mapping(address => bool) private _defaultApprovals;

  event DefaultApprovalSet(address indexed operator, bool indexed status);

  function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
    return _defaultApprovals[operator] || super.isApprovedForAll(owner, operator);
  }

  function _setDefaultApproval(address operator, bool status) internal {
    require(_defaultApprovals[operator] != status, "DefaultApproval: default approval already set");
    _defaultApprovals[operator] = status;
    emit DefaultApprovalSet(operator, status);
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual override returns (bool) {
    return _defaultApprovals[spender] || super._isApprovedOrOwner(spender, tokenId);
  }

  // solhint-disable-next-line ordering
  uint256[50] private __gap;
}