// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Secure {
  event AddedBlackList(address indexed user);
  event RemovedBlackList(address indexed user);

  bool internal locked;

  address public owner;

  uint8 public BASE_PERCENT = 30;

  uint32 public FEE = 100000000;

  uint64 public MINIMUM_INVEST = 5000000000;

  mapping(address => bool) public blacklist;

  modifier onlyOwner() {
    require(_msgSender() == owner, "OWN");
    _;
  }

  modifier secured() {
    require(!blacklist[_msgSender()], "BLK");
    require(!locked, "REN");
    locked = true;
    _;
    locked = false;
  }

  function _msgSender() internal view returns (address) {
    return msg.sender;
  }

  function _safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{gas: 23000, value: value}("");

    require(success, "ETH");
  }

  function lock() external onlyOwner {
    locked = true;
  }

  function unlock() external onlyOwner {
    locked = false;
  }

  function changeFee(uint32 fee) external onlyOwner {
    FEE = fee;
  }

  function changeBasePercent(uint8 percent) external onlyOwner {
    BASE_PERCENT = percent;
  }

  function addBlackList(address user) external onlyOwner {
    blacklist[user] = true;
    emit AddedBlackList(user);
  }

  function removeBlackList(address user) external onlyOwner {
    blacklist[user] = false;
    emit RemovedBlackList(user);
  }

  function changeMinimumInvest(uint64 amount) external onlyOwner {
    MINIMUM_INVEST = amount;
  }

  function changeOwner(address newOwner) external onlyOwner {
    owner = newOwner;
  }

  function withdrawBnb(uint256 value) external onlyOwner {
    payable(owner).transfer(value);
  }
}