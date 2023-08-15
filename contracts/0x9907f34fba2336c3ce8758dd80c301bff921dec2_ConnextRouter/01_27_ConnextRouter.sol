// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title ConnextRouter
 *
 * @author Fujidao Labs
 *
 * @notice A Router implementing Connext specific bridging logic.
 */

import {IERC20, SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IConnext, IXReceiver} from "../interfaces/connext/IConnext.sol";
import {ConnextReceiver} from "./ConnextReceiver.sol";
import {ConnextHandler} from "./ConnextHandler.sol";
import {BaseRouter} from "../abstracts/BaseRouter.sol";
import {IWETH9} from "../abstracts/WETH9.sol";
import {IVault} from "../interfaces/IVault.sol";
import {IVaultPermissions} from "../interfaces/IVaultPermissions.sol";
import {IChief} from "../interfaces/IChief.sol";
import {IRouter} from "../interfaces/IRouter.sol";
import {IFlasher} from "../interfaces/IFlasher.sol";
import {LibBytes} from "../libraries/LibBytes.sol";

contract ConnextRouter is BaseRouter, IXReceiver {
  using SafeERC20 for IERC20;

  /**
   * @dev Emitted when a new destination ConnextReceiver gets added.
   *
   * @param router ConnextReceiver on another chain
   * @param domain the destination domain identifier according Connext nomenclature
   */
  event NewConnextReceiver(address indexed router, uint256 indexed domain);

  /**
   * @dev Emitted when Connext `xCall` is invoked.
   *
   * @param transferId the unique identifier of the crosschain transfer
   * @param caller the account that called the function
   * @param receiver the router on destDomain
   * @param destDomain the destination domain identifier according Connext nomenclature
   * @param asset the asset being transferred
   * @param amount the amount of transferring asset the recipient address receives
   * @param callData the calldata sent to destination router that will get decoded and executed
   */
  event XCalled(
    bytes32 indexed transferId,
    address indexed caller,
    address indexed receiver,
    uint256 destDomain,
    address asset,
    uint256 amount,
    bytes callData
  );

  /**
   * @dev Emitted when the router receives a cross-chain call.
   *
   * @param transferId the unique identifier of the crosschain transfer
   * @param originDomain the origin domain identifier according Connext nomenclature
   * @param success whether or not the xBundle call succeeds
   * @param asset the asset being transferred
   * @param amount the amount of transferring asset the recipient address receives
   * @param callData the calldata that will get decoded and executed
   */
  event XReceived(
    bytes32 indexed transferId,
    uint256 indexed originDomain,
    bool success,
    address asset,
    uint256 amount,
    bytes callData
  );

  /// @dev Custom Errors
  error ConnextRouter__setRouter_invalidInput();
  error ConnextRouter__xReceive_notAllowedCaller();
  error ConnextRouter__xReceiver_noValueTransferUseXbundle();
  error ConnnextRouter__xBundleConnext_notSelfCalled();
  error ConnextRouter__crossTransfer_checkReceiver();

  /// @dev The connext contract on the origin domain.
  IConnext public immutable connext;

  ConnextHandler public immutable handler;
  address public immutable connextReceiver;

  /**
   * @notice A mapping of a domain of another chain and a deployed ConnextReceiver there.
   *
   * @dev For the list of domains supported by Connext,
   * plz check: https://docs.connext.network/resources/deployments
   */
  mapping(uint256 => address) public receiverByDomain;

  modifier onlySelf() {
    if (msg.sender != address(this)) {
      revert ConnnextRouter__xBundleConnext_notSelfCalled();
    }
    _;
  }

  modifier onlyConnextReceiver() {
    if (msg.sender != connextReceiver) {
      revert ConnextRouter__xReceive_notAllowedCaller();
    }
    _;
  }

  constructor(IWETH9 weth, IConnext connext_, IChief chief) BaseRouter(weth, chief) {
    connext = connext_;
    connextReceiver = address(new ConnextReceiver(address(this)));
    handler = new ConnextHandler(address(this));
    _allowCaller(msg.sender, true);
  }

  /*////////////////////////////////////
        Connext specific functions
  ////////////////////////////////////*/

  /**
   * @notice Called by Connext on the destination chain.
   *
   * @param transferId the unique identifier of the crosschain transfer
   * @param amount the amount of transferring asset, after slippage, the recipient address receives
   * @param asset the asset being transferred
   * @param originSender the address of the contract or EOA that called xcall on the origin chain
   * @param originDomain the origin domain identifier according Connext nomenclature
   * @param callData the calldata that will get decoded and executed, see "Requirements"
   *
   * @dev It does not perform authentication of the calling address. As a result of that,
   * all txns go through Connext's fast path.
   * If `xBundle` fails internally, this contract will send the received funds to {ConnextHandler}.
   *
   * Requirements:
   * - `calldata` parameter must be encoded with the following structure:
   *     > abi.encode(Action[] actions, bytes[] args)
   * - actions: array of serialized actions to execute from available enum {IRouter.Action}.
   * - args: array of encoded arguments according to each action. See {BaseRouter-internalBundle}.
   */
  function xReceive(
    bytes32 transferId,
    uint256 amount,
    address asset,
    address originSender,
    uint32 originDomain,
    bytes memory callData
  )
    external
    onlyConnextReceiver
    returns (bytes memory)
  {
    (Action[] memory actions, bytes[] memory args) = abi.decode(callData, (Action[], bytes[]));

    Snapshot memory tokenToCheck_ = Snapshot(asset, IERC20(asset).balanceOf(address(this)));

    IERC20(asset).safeTransferFrom(connextReceiver, address(this), amount);
    /**
     * @dev Due to the AMM nature of Connext, there could be some slippage
     * incurred on the amount that this contract receives after bridging.
     * There is also a routing fee of 0.05% of the bridged amount.
     * The slippage can't be calculated upfront so that's why we need to
     * replace `amount` in the encoded args for the first action if
     * the action is Deposit, or Payback.
     */
    uint256 beforeSlipped;
    (args[0], beforeSlipped) = _accountForSlippage(amount, actions[0], args[0]);

    /**
     * @dev Connext will keep the custody of the bridged amount if the call
     * to `xReceive` fails. That's why we need to ensure the funds are not stuck at Connext.
     * Therefore we try/catch instead of directly calling _bundleInternal(...).
     */
    try this.xBundleConnext(actions, args, beforeSlipped, tokenToCheck_) {
      emit XReceived(transferId, originDomain, true, asset, amount, callData);
    } catch {
      IERC20(asset).safeTransfer(address(handler), amount);
      handler.recordFailed(transferId, amount, asset, originSender, originDomain, actions, args);

      emit XReceived(transferId, originDomain, false, asset, amount, callData);
    }

    return "";
  }

  /**
   * @notice Function selector created to allow try-catch procedure in Connext message data
   * passing.Including argument for `beforeSlipepd` not available in {BaseRouter-xBundle}.
   *
   * @param actions an array of actions that will be executed in a row
   * @param args an array of encoded inputs needed to execute each action
   * @param beforeSlipped amount passed by the origin cross-chain router operation
   * @param tokenToCheck_ snapshot after xReceive from Connext
   *
   * @dev Requirements:
   * - Must only be called within the context of this same contract.
   */
  function xBundleConnext(
    Action[] calldata actions,
    bytes[] calldata args,
    uint256 beforeSlipped,
    Snapshot memory tokenToCheck_
  )
    external
    payable
    onlySelf
  {
    _bundleInternal(actions, args, beforeSlipped, tokenToCheck_);
  }

  /**
   * @dev Decodes and replaces "amount" argument in args with `receivedAmount`
   * in Deposit, or Payback.
   *
   * Refer to:
   * https://github.com/Fujicracy/fuji-v2/issues/253#issuecomment-1385995095
   */
  function _accountForSlippage(
    uint256 receivedAmount,
    Action action,
    bytes memory args
  )
    private
    pure
    returns (bytes memory newArgs, uint256 beforeSlipped)
  {
    uint256 prevAmount;
    (newArgs, prevAmount) = _replaceAmountArgInAction(action, args, receivedAmount);
    if (prevAmount != receivedAmount) {
      beforeSlipped = prevAmount;
    }
  }

  /**
   * @dev NOTE to integrators
   * The `beneficiary_`, of a `_crossTransfer(...)` must meet these requirement:
   * - Must be an externally owned account (EOA) or
   * - Must be a contract that implements or is capable of calling:
   *   - connext.forceUpdateSlippage(TransferInfo, _slippage) add the destination chain.
   * Refer to 'delegate' argument:
   * https://docs.connext.network/developers/guides/handling-failures#increasing-slippage-tolerance
   */
  /// @inheritdoc BaseRouter
  function _crossTransfer(
    bytes memory params,
    address beneficiary
  )
    internal
    override
    returns (address)
  {
    (
      uint256 destDomain,
      uint256 slippage,
      address asset,
      uint256 amount,
      address receiver,
      address sender
    ) = abi.decode(params, (uint256, uint256, address, uint256, address, address));

    _checkIfAddressZero(receiver);
    /// @dev In a simple _crossTransfer funds should not be left in destination `ConnextRouter.sol`
    if (receiver == receiverByDomain[destDomain]) {
      revert ConnextRouter__crossTransfer_checkReceiver();
    }
    address beneficiary_ = _checkBeneficiary(beneficiary, receiver);

    _safePullTokenFrom(asset, sender, amount);
    /// @dev Reassign if the encoded amount differs from the available balance (for ex. after soft withdraw or payback)
    uint256 balance = IERC20(asset).balanceOf(address(this));
    uint256 amount_ = balance < amount ? balance : amount;
    _safeApprove(asset, address(connext), amount_);

    bytes32 transferId = connext.xcall(
      // _destination: Domain ID of the destination chain
      uint32(destDomain),
      // _to: address of the target contract
      receiver,
      // _asset: address of the token contract
      asset,
      // _delegate: address that has rights to update the original slippage tolerance
      // by calling Connext's forceUpdateSlippage function
      beneficiary_,
      // _amount: amount of tokens to transfer
      amount_,
      // _slippage: can be anything between 0-10000 becaus
      // the maximum amount of slippage the user will accept in BPS, 30 == 0.3%
      slippage,
      // _callData: empty because we're only sending funds
      ""
    );
    emit XCalled(transferId, msg.sender, receiver, destDomain, asset, amount, "");

    return beneficiary_;
  }

  /**
   * @dev NOTE to integrators
   * The `beneficiary_`, of a `_crossTransferWithCalldata(...)` must meet these requirement:
   * - Must be an externally owned account (EOA) or
   * - Must be a contract that implements or is capable of calling:
   *   - connext.forceUpdateSlippage(TransferInfo, _slippage) add the destination chain.
   * Refer to 'delegate' argument:
   * https://docs.connext.network/developers/guides/handling-failures#increasing-slippage-tolerance
   */
  /// @inheritdoc BaseRouter
  function _crossTransferWithCalldata(
    bytes memory params,
    address beneficiary
  )
    internal
    override
    returns (address beneficiary_)
  {
    (
      uint256 destDomain,
      uint256 slippage,
      address asset,
      uint256 amount,
      address sender,
      bytes memory callData
    ) = abi.decode(params, (uint256, uint256, address, uint256, address, bytes));

    (Action[] memory actions, bytes[] memory args) = abi.decode(callData, (Action[], bytes[]));

    beneficiary_ = _checkBeneficiary(beneficiary, _getBeneficiaryFromCalldata(actions, args));

    address to_ = receiverByDomain[destDomain];
    _checkIfAddressZero(to_);

    _safePullTokenFrom(asset, sender, amount);
    _safeApprove(asset, address(connext), amount);

    bytes32 transferId = connext.xcall(
      // _destination: Domain ID of the destination chain
      uint32(destDomain),
      // _to: address of the target contract
      to_,
      // _asset: address of the token contract
      asset,
      // _delegate: address that can revert or forceLocal on destination
      beneficiary_,
      // _amount: amount of tokens to transfer
      amount,
      // _slippage: can be anything between 0-10000 becaus
      // the maximum amount of slippage the user will accept in BPS, 30 == 0.3%
      slippage,
      // _callData: the encoded calldata to send
      callData
    );

    emit XCalled(
      transferId, msg.sender, receiverByDomain[destDomain], destDomain, asset, amount, callData
    );

    return beneficiary_;
  }

  /// @inheritdoc BaseRouter
  function _replaceAmountInCrossAction(
    Action action,
    bytes memory args,
    uint256 updateAmount
  )
    internal
    pure
    override
    returns (bytes memory newArgs, uint256 previousAmount)
  {
    if (action == Action.XTransfer) {
      (
        uint256 destDomain,
        uint256 slippage,
        address asset,
        uint256 amount,
        address receiver,
        address sender
      ) = abi.decode(args, (uint256, uint256, address, uint256, address, address));
      previousAmount = amount;
      newArgs = abi.encode(destDomain, slippage, asset, updateAmount, receiver, sender);
    } else if (action == Action.XTransferWithCall) {
      (
        uint256 destDomain,
        uint256 slippage,
        address asset,
        uint256 amount,
        address sender,
        bytes memory callData
      ) = abi.decode(args, (uint256, uint256, address, uint256, address, bytes));
      previousAmount = amount;
      newArgs = abi.encode(destDomain, slippage, asset, updateAmount, sender, callData);
    }
  }

  /// @inheritdoc BaseRouter
  function _getBeneficiaryFromCalldata(
    Action[] memory actions,
    bytes[] memory args
  )
    internal
    view
    override
    returns (address beneficiary_)
  {
    if (actions[0] == Action.Deposit || actions[0] == Action.Payback) {
      // For Deposit or Payback.
      (,, address receiver,) = abi.decode(args[0], (IVault, uint256, address, address));
      beneficiary_ = receiver;
    } else if (actions[0] == Action.Withdraw || actions[0] == Action.Borrow) {
      // For Withdraw or Borrow
      (,,, address owner) = abi.decode(args[0], (IVault, uint256, address, address));
      beneficiary_ = owner;
    } else if (actions[0] == Action.WithdrawETH) {
      // For WithdrawEth
      (, address receiver) = abi.decode(args[0], (uint256, address));
      beneficiary_ = receiver;
    } else if (actions[0] == Action.PermitBorrow || actions[0] == Action.PermitWithdraw) {
      (, address owner,,,,,,) = abi.decode(
        args[0], (IVaultPermissions, address, address, uint256, uint256, uint8, bytes32, bytes32)
      );
      beneficiary_ = owner;
    } else if (actions[0] == Action.Flashloan) {
      (,,,, Action[] memory newActions, bytes[] memory newArgs) =
        abi.decode(args[0], (IFlasher, address, uint256, address, Action[], bytes[]));

      beneficiary_ = _getBeneficiaryFromCalldata(newActions, newArgs);
    } else if (actions[0] == Action.XTransfer) {
      (,,,, address receiver,) =
        abi.decode(args[0], (uint256, uint256, address, uint256, address, address));
      beneficiary_ = receiver;
    } else if (actions[0] == Action.XTransferWithCall) {
      (,,,, bytes memory callData) =
        abi.decode(args[0], (uint256, uint256, address, uint256, bytes));

      (Action[] memory actions_, bytes[] memory args_) = abi.decode(callData, (Action[], bytes[]));

      beneficiary_ = _getBeneficiaryFromCalldata(actions_, args_);
    } else if (actions[0] == Action.DepositETH) {
      /// @dev depositETH cannot be actions[0] in ConnextRouter or inner-flashloan
      revert BaseRouter__bundleInternal_notFirstAction();
    } else if (actions[0] == Action.Swap) {
      /// @dev swap cannot be actions[0].
      revert BaseRouter__bundleInternal_notFirstAction();
    }
  }

  /**
   * @notice Anyone can call this function on the origin domain to increase the relayer fee for a transfer.
   *
   * @param transferId the unique identifier of the crosschain transaction
   */
  function bumpTransfer(bytes32 transferId) external payable {
    connext.bumpTransfer{value: msg.value}(transferId);
  }

  /**
   * @notice Registers an address of the ConnextReceiver deployed on another chain.
   *
   * @param domain unique identifier of a chain as defined in
   * https://docs.connext.network/resources/deployments
   * @param receiver address of ConnextReceiver deployed on the chain defined by its domain
   *
   * @dev The mapping domain -> receiver is used in `xReceive` to verify the origin sender.
   * Requirements:
   *  - Must be restricted to timelock.
   *  - `receiver` must be a non-zero address.
   */
  function setReceiver(uint256 domain, address receiver) external onlyTimelock {
    _checkIfAddressZero(receiver);
    receiverByDomain[domain] = receiver;

    emit NewConnextReceiver(receiver, domain);
  }
}