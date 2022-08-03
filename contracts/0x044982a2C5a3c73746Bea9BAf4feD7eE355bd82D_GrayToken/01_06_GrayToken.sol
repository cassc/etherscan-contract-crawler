// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GrayToken is ERC20, Ownable {
  constructor() ERC20("Gray Token", "GRAY") {}

  function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount);
  }

  function batchTransfer(address[] calldata recipients, uint256[] calldata amounts) public returns (uint256) {
    require(recipients.length > 0, "No recipients");
    require(recipients.length == amounts.length, "amounts argument size mismatched");

    uint256 amountsTotal;

    for (uint256 i = 0; i < recipients.length; i++) {
      amountsTotal += amounts[i];
      transfer(recipients[i], amounts[i]);
    }

    return amountsTotal;
  }
}