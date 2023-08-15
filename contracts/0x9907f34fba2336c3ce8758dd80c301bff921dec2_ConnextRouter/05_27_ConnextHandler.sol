// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title ConnextHandler
 *
 * @author Fujidao Labs
 *
 * @notice Handles failed transactions from Connext and keeps custody of
 * the transferred funds.
 */

import {ConnextRouter} from "./ConnextRouter.sol";
import {IRouter} from "../interfaces/IRouter.sol";
import {IVault} from "../interfaces/IVault.sol";
import {ISwapper} from "../interfaces/ISwapper.sol";
import {IERC20, SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract ConnextHandler {
  using SafeERC20 for IERC20;
  /**
   * @dev Contains the information of a failed transaction.
   */

  struct FailedTxn {
    bytes32 transferId;
    uint256 amount;
    address asset;
    address originSender;
    uint32 originDomain;
    IRouter.Action[] actions;
    bytes[] args;
    uint256 nonce;
    bool executed;
  }

  /**
   * @dev Emitted when a failed transaction is recorded.
   *
   * @param transferId  unique id of the cross-chain txn
   * @param amount transferred
   * @param asset being transferred
   * @param originSender of the cross-chain txn
   * @param originDomain of the cross-chain txn
   * @param actions to be called in xBundle
   * @param args to be called for each action in xBundle
   * @param nonce of failed txn
   */
  event FailedTxnRecorded(
    bytes32 indexed transferId,
    uint256 amount,
    address asset,
    address originSender,
    uint32 originDomain,
    IRouter.Action[] actions,
    bytes[] args,
    uint256 nonce
  );

  /**
   * @dev Emitted when a failed transaction gets retried.
   *
   * @param transferId the unique identifier of the cross-chain txn
   * @param success boolean
   * @param oldArgs of the failed transaction
   * @param newArgs attemped in execution
   */
  event FailedTxnExecuted(
    bytes32 indexed transferId,
    IRouter.Action[] oldActions,
    IRouter.Action[] newActions,
    bytes[] oldArgs,
    bytes[] newArgs,
    uint256 nonce,
    bool indexed success
  );

  /// @dev Custom errors
  error ConnextHandler__callerNotConnextRouter();
  error ConnextHandler__executeFailed_emptyTxn();
  error ConnextHandler__executeFailed_tranferAlreadyExecuted(bytes32 transferId, uint256 nonce);

  bytes32 private constant ZERO_BYTES32 =
    0x0000000000000000000000000000000000000000000000000000000000000000;

  ConnextRouter public immutable connextRouter;

  /**
   * @dev Maps a failed transferId -> calldata[]
   * Multiple failed attempts are registered with nonce
   */
  mapping(bytes32 => FailedTxn[]) private _failedTxns;

  modifier onlyConnextRouter() {
    if (msg.sender != address(connextRouter)) {
      revert ConnextHandler__callerNotConnextRouter();
    }
    _;
  }

  /// @dev Modifier that checks `msg.sender` is an allowed called in {ConnextRouter}.
  modifier onlyAllowedCaller() {
    if (!connextRouter.isAllowedCaller(msg.sender)) {
      revert ConnextHandler__callerNotConnextRouter();
    }
    _;
  }

  /**
   * @notice Constructor that initialized
   */
  constructor(address connextRouter_) {
    connextRouter = ConnextRouter(payable(connextRouter_));
  }

  /**
   * @notice Returns the struct of failed transaction by `transferId`.
   *
   * @param transferId the unique identifier of the cross-chain txn
   * @param nonce or position in the array of the failed attempts to execute
   */
  function getFailedTxn(bytes32 transferId, uint256 nonce) public view returns (FailedTxn memory) {
    return _failedTxns[transferId][nonce];
  }

  function getFailedTxnNextNonce(bytes32 transferId) public view returns (uint256 next) {
    return _failedTxns[transferId].length;
  }

  /**
   * @notice Records a failed {ConnextRouter-xReceive} call.
   *
   * @param transferId the unique identifier of the cross-chain txn
   * @param amount the amount of transferring asset, after slippage, the recipient address receives
   * @param asset the asset being transferred
   * @param originSender the address of the contract or EOA that called xcall on the origin chain
   * @param originDomain the origin domain identifier according Connext nomenclature
   * @param actions that should be executed in {BaseRouter-internalBundle}
   * @param args for the actions
   *
   * @dev At this point of execution {ConnextRouter} sent all balance of `asset` to this contract.
   * It has already been verified that `amount` of `asset` is >= to balance sent.
   * This function does not need to emit an event since {ConnextRouter} already emit
   * a failed `XReceived` event.
   */
  function recordFailed(
    bytes32 transferId,
    uint256 amount,
    address asset,
    address originSender,
    uint32 originDomain,
    IRouter.Action[] memory actions,
    bytes[] memory args
  )
    external
    onlyConnextRouter
  {
    uint256 nextNonce = getFailedTxnNextNonce(transferId);
    _failedTxns[transferId].push(
      FailedTxn(
        transferId, amount, asset, originSender, originDomain, actions, args, nextNonce, false
      )
    );

    emit FailedTxnRecorded(
      transferId, amount, asset, originSender, originDomain, actions, args, nextNonce
    );
  }

  /**
   * @notice Executes a failed transaction with update `args`
   *
   * @param transferId the unique identifier of the cross-chain txn
   * @param nonce or position in the array of the failed attempts to execute
   * @param actions  that will replace actions of failed txn
   * @param args taht will replace args of failed txn
   *
   * @dev Requirements:
   * - Must only be called by an allowed caller in {ConnextRouter}.
   * - Must clear the txn from `_failedTxns` mapping if execution succeeds.
   * - Must replace `sender` in `args` for value tranfer type actions (Deposit-Payback-Swap}.
   */
  function executeFailedWithUpdatedArgs(
    bytes32 transferId,
    uint256 nonce,
    IRouter.Action[] memory actions,
    bytes[] memory args
  )
    external
    onlyAllowedCaller
  {
    FailedTxn memory txn = _failedTxns[transferId][nonce];

    if (txn.transferId == ZERO_BYTES32 || txn.originDomain == 0) {
      revert ConnextHandler__executeFailed_emptyTxn();
    } else if (txn.executed) {
      revert ConnextHandler__executeFailed_tranferAlreadyExecuted(transferId, nonce);
    }

    IERC20(txn.asset).safeIncreaseAllowance(address(connextRouter), txn.amount);
    _failedTxns[transferId][nonce].executed = true;

    try connextRouter.xBundle(actions, args) {
      emit FailedTxnExecuted(transferId, txn.actions, actions, txn.args, args, nonce, true);
    } catch {
      _failedTxns[transferId][nonce].executed = false;
      IERC20(txn.asset).safeDecreaseAllowance(address(connextRouter), txn.amount);

      emit FailedTxnExecuted(transferId, txn.actions, actions, txn.args, args, nonce, false);
    }
  }

  /**
   * @notice Rescue stuck funds due to failed cross-chain calls (cf. ConnextRouter).
   *
   * @param token the address of the ERC-20 token to sweep
   * @param receiver the address that will receive the swept funds
   * @param amount amount to sweep
   */
  function sweepToken(IERC20 token, address receiver, uint256 amount) external onlyAllowedCaller {
    token.safeTransfer(receiver, amount);
  }
}