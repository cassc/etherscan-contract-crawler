// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract WithdrawSilly is Ownable, ReentrancyGuard {

  constructor() {}

  function withdraw() external onlyOwner nonReentrant {
    require(address(this).balance > 0, "Empty!");
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");
    require(success, "Transaction Failed");
  }

}