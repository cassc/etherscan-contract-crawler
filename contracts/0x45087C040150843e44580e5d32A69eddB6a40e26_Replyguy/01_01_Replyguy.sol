// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Replyguy {
  address public owner;
  uint256 public cost;
  error ErrNotOwner();
  error ErrValueSize();
  event Comment(address indexed poster, bytes32 indexed url, bytes32 text);
  constructor(uint256 _cost, address _owner) {
    cost = _cost;
    owner = _owner;
  }
  modifier onlyOwner() {
    if (msg.sender != owner) revert ErrNotOwner();
    _;
  }
  function configure(uint256 _cost, address _owner) external onlyOwner {
    cost = _cost;
    owner = _owner;
  }
  function comment(bytes32 url, bytes32 text) external payable {
    if (msg.value < cost) revert ErrValueSize();
    emit Comment(msg.sender, url, text);
    payable(owner).transfer(msg.value);
  }
}