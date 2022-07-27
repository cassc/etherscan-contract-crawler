// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

/**
 * @title Safe ERC20 Transfer
 * @notice Reverts when transfer is not successful
 * @author Goldfinch
 */
library SafeERC20Transfer {
  function safeERC20Transfer(
    IERC20 erc20,
    address to,
    uint256 amount,
    string memory message
  ) internal {
    /// @dev ZERO address
    require(to != address(0), "ZERO");
    bool success = erc20.transfer(to, amount);
    require(success, message);
  }

  function safeERC20Transfer(
    IERC20 erc20,
    address to,
    uint256 amount
  ) internal {
    safeERC20Transfer(erc20, to, amount, "");
  }

  function safeERC20TransferFrom(
    IERC20 erc20,
    address from,
    address to,
    uint256 amount,
    string memory message
  ) internal {
    require(to != address(0), "ZERO");
    bool success = erc20.transferFrom(from, to, amount);
    require(success, message);
  }

  function safeERC20TransferFrom(
    IERC20 erc20,
    address from,
    address to,
    uint256 amount
  ) internal {
    safeERC20TransferFrom(erc20, from, to, amount, "");
  }

  function safeERC20Approve(
    IERC20 erc20,
    address spender,
    uint256 allowance,
    string memory message
  ) internal {
    bool success = erc20.approve(spender, allowance);
    require(success, message);
  }

  function safeERC20Approve(
    IERC20 erc20,
    address spender,
    uint256 allowance
  ) internal {
    safeERC20Approve(erc20, spender, allowance, "");
  }
}