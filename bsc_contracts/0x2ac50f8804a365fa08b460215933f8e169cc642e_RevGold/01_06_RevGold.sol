// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RevGold is Ownable {
  mapping(address => uint256) public balancesForContract;
  address[] public allAdmins;
  uint256 public withdrawFee;
  address[] private availableTokens;

  event DepositAction(
    uint256 amount,
    address userAddress,
    address tokenAddress
  );
  event WithdrawAction(
    uint256 amount,
    address userAddress,
    address tokenAddress
  );

  constructor() {
    addAdmin(owner());
    withdrawFee = 250;
  }

  function updateTokens(address[] memory tokens) public onlyAdmin {
    delete availableTokens;
    for (uint256 i = 0; i < tokens.length; ++i) {
      availableTokens.push(tokens[i]);
    }
  }

  function getTokens() public view returns (address[] memory) {
    return availableTokens;
  }

  function isAdmin() public view returns (bool) {
    return findAdmin(_msgSender()) >= 0 || (owner() == _msgSender());
  }

  modifier onlyAdmin() {
    require(isAdmin(), "Adminable: Admin role require");
    _;
  }

  function findAdmin(address admin) private view returns (int256) {
    for (uint256 i = 0; i < allAdmins.length; i++) {
      if (allAdmins[i] == admin) return int256(i);
    }
    return -1;
  }

  function getAllAdmins() public view onlyAdmin returns (address[] memory) {
    return allAdmins;
  }

  function getOwner() public view returns (address) {
    return owner();
  }

  function addAdmin(address admin) public onlyAdmin {
    allAdmins.push(admin);
  }

  function removeAdmin(address admin) public onlyAdmin {
    int256 index = findAdmin(admin);
    delete allAdmins[uint256(index)];
  }

  function updateFee(uint256 fee) public onlyAdmin {
    require(fee > 0, "Fee require greater then 1");
    withdrawFee = fee;
  }

  function deposit(uint256 amount, address tokenAddress) external {
    address userAddress = _msgSender();
    ERC20(tokenAddress).transferFrom(userAddress, address(this), amount);
    balancesForContract[tokenAddress] += amount;
    emit DepositAction(amount, userAddress, tokenAddress);
  }

  function withdraw(uint256 amount, address tokenAddress) external {
    address userAddress = _msgSender();
    require(balancesForContract[tokenAddress] >= amount, "Not enough money!");
    ERC20(tokenAddress).transfer(userAddress, amount);
    balancesForContract[tokenAddress] -= amount;
    emit WithdrawAction(amount, userAddress, tokenAddress);
  }
}