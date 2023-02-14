// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LTransfers {
  function internalTransferFrom(
    address from,
    address to,
    uint256 amount,
    IERC20 erc20
  ) internal {
    require(amount > 0, "ERROR: Amount must be greater than 0");
    require(erc20.balanceOf(from) >= amount, "ERROR: Insufficient funds");
    require(erc20.allowance(from, address(this)) >= amount, "ERROR: You must approve the token transaction");

    require(erc20.transferFrom(from, to, amount), "ERROR: Transfer failed");
  }

  function internalTransferTo(
    address to,
    uint256 amount,
    IERC20 erc20
  ) internal {
    require(amount > 0, "ERROR: Amount must be greater than 0");
    require(erc20.transfer(to, amount), "ERROR: Transfer failed");
  }

  function internalTransferToETH(address to, uint256 amount) internal {
    require(amount > 0, "ERROR: Amount must be greater than 0");
    bool sent = false;
    (sent, ) = to.call{value: amount}("");
    require(sent, "Failed to send Ether");
  }
}