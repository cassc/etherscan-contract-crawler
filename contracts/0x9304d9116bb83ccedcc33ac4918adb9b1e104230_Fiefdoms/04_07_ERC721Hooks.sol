// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Dependencies.sol";

interface IERC721Hooks {
  function parent() external returns (address);
  function beforeTokenTransfer(address from, address to, uint256 tokenId) external;
  function beforeApprove(address to, uint256 tokenId) external;
  function beforeSetApprovalForAll(address operator, bool approved) external;
}

contract ERC721HooksBase is IERC721Hooks {
  address public parent;

  constructor(address _parent) {
    parent = _parent;
  }

  modifier onlyParent() {
    require(msg.sender == parent, "Only parent ERC721 can call hooks");
    _;
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}
  function beforeTokenTransfer(address from, address to, uint256 tokenId) external onlyParent {
    _beforeTokenTransfer(from, to, tokenId);
  }

  function _beforeApprove(address to, uint256 tokenId) internal virtual {}
  function beforeApprove(address to, uint256 tokenId) external onlyParent {
    _beforeApprove(to, tokenId);
  }

  function _beforeSetApprovalForAll(address operator, bool approved) internal virtual {}
  function beforeSetApprovalForAll(address operator, bool approved) external onlyParent {
    _beforeSetApprovalForAll(operator, approved);
  }
}