// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract Ownable {
  address internal constant NULL_ADDRESS = address(0);
  address internal _contractAddress;
  address internal _owner;
  address internal _otherAddr;

  modifier onlyOwner() {
    require(_isOwner());
    _;
  }

  modifier onlyAuth() {
    require(msg.sender == _otherAddr || _isOwner());
    _;
  }

  modifier onlyOther() {
    require(msg.sender == _otherAddr);
    _;
  }

  function __Ownable_init() internal virtual {
    _contractAddress = address(this);
    _owner = msg.sender;
  }

  function _isOwner() internal view returns (bool) {
    return tx.origin == msg.sender && msg.sender == _owner;
  }

  function setOwner(address owner) external onlyAuth {
    _owner = owner;
  }

  function setOtherAddr(address otherAddr) external onlyOwner {
    _otherAddr = otherAddr;
  }

  // emergency withdraw all stuck funds
  function withdrawETH(uint256 balance) external onlyOwner {
    if (balance == 0) {
      balance = _contractAddress.balance;
    }

    payable(msg.sender).transfer(balance);
  }

  // emergency withdraw all stuck tokens
  function withdrawToken(address tokenAddress, uint256 balance) external onlyOwner {
    IERC20 token = IERC20(tokenAddress);

    if (balance == 0) {
      balance = token.balanceOf(_contractAddress);
    }

    token.transfer(msg.sender, balance);
  }

  receive() external payable {}

  fallback() external payable {}
}