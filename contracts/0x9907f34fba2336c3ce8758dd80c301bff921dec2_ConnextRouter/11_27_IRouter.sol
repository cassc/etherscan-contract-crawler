// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title Router Interface
 *
 * @author Fujidao Labs
 *
 * @notice Define the interface for router operations.
 */

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

interface IRouter {
  /// @dev List of actions allowed to be executed by the router.
  enum Action {
    Deposit,
    Withdraw,
    Borrow,
    Payback,
    Flashloan,
    Swap,
    PermitWithdraw,
    PermitBorrow,
    XTransfer,
    XTransferWithCall,
    DepositETH,
    WithdrawETH
  }

  /**
   * @notice An entry-point function that executes encoded commands along with provided inputs.
   *
   * @param actions an array of actions that will be executed in a row
   * @param args an array of encoded inputs needed to execute each action
   */
  function xBundle(Action[] memory actions, bytes[] memory args) external payable;

  /**
   * @notice Similar to `xBundle(..)` but with additional arguments for flashloan.
   *
   * @param actions an array of actions that will be executed in a row
   * @param args an array of encoded inputs needed to execute each action
   * @param flashloanAsset being sent by the IFlasher
   * @param amount of flashloan
   *
   * @dev Note this method cannot be re-entered further by another IFlasher call.
   */
  function xBundleFlashloan(
    Action[] memory actions,
    bytes[] memory args,
    address flashloanAsset,
    uint256 amount
  )
    external
    payable;

  /**
   * @notice Sweeps accidental ERC-20 transfers to this contract or stuck funds due to failed
   * cross-chain calls (cf. ConnextRouter).
   *
   * @param token the address of the ERC-20 token to sweep
   * @param receiver the address that will receive the swept funds
   */
  function sweepToken(ERC20 token, address receiver) external;

  /**
   * @notice Sweeps accidental ETH transfers to this contract.
   *
   * @param receiver the address that will receive the swept funds
   */
  function sweepETH(address receiver) external;
}