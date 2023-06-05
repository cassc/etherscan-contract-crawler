// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15
pragma solidity ^0.8.15;

import { IERC20Upgradeable as IERC20 } from "openzeppelin-contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

struct Escrow {
  /// @notice The escrowed token
  IERC20 token;
  /// @notice Timestamp of the start of the unlock
  uint32 start;
  /// @notice The timestamp the unlock ends at
  uint32 end;
  /// @notice The timestamp the index was last updated at
  uint32 lastUpdateTime;
  /// @notice Initial balance of the escrow
  uint256 initialBalance;
  /// @notice Current balance of the escrow
  uint256 balance;
  /// @notice Owner of the escrow
  address account;
}

struct Fee {
  /// @notice Accrued fee amount
  uint256 accrued;
  /// @notice Fee percentage in 1e18 for 100% (1 BPS = 1e14)
  uint256 feePerc;
}

interface IMultiRewardEscrow {
  function lock(
    IERC20 token,
    address account,
    uint256 amount,
    uint32 duration,
    uint32 offset
  ) external;

  function setFees(IERC20[] memory tokens, uint256[] memory tokenFees) external;

  function fees(IERC20 token) external view returns (Fee memory);
}