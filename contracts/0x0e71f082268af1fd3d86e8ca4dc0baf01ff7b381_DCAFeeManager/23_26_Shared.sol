// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @notice An amount to take form the caller
struct TakeFromCaller {
  // The token that will be taken from the caller
  IERC20 token;
  // The amount that will be taken
  uint256 amount;
}

/// @notice An allowance to provide for the swaps to work
struct Allowance {
  // The token that should be approved
  IERC20 token;
  // The spender
  address allowanceTarget;
  // The minimum allowance needed
  uint256 minAllowance;
}

/// @notice A swap to execute
struct Swap {
  // The index of the swapper in the list of swappers
  uint8 swapperIndex;
  // The data to send to the swapper
  bytes swapData;
}

/// @notice A token that was left on the contract and should be transferred out
struct TransferOutBalance {
  // The token to transfer
  address token;
  // The recipient of those tokens
  address recipient;
}

/// @notice Context necessary for the swap execution
struct SwapContext {
  // The index of the swapper that should execute each swap. This might look strange but it's way cheaper than alternatives
  uint8 swapperIndex;
  // The ETH/MATIC/BNB to send as part of the swap
  uint256 value;
}