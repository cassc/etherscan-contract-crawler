// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @title BaseRouter
 *
 * @author Fujidao Labs
 *
 * @notice Abstract contract to be inherited by all routers.
 */

import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20, IERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IRouter} from "../interfaces/IRouter.sol";
import {ISwapper} from "../interfaces/ISwapper.sol";
import {IVault} from "../interfaces/IVault.sol";
import {IChief} from "../interfaces/IChief.sol";
import {IFlasher} from "../interfaces/IFlasher.sol";
import {IVaultPermissions} from "../interfaces/IVaultPermissions.sol";
import {SystemAccessControl} from "../access/SystemAccessControl.sol";
import {ReentrancyGuard} from "../helpers/ReentrancyGuard.sol";
import {IWETH9} from "../abstracts/WETH9.sol";
import {LibBytes} from "../libraries/LibBytes.sol";

abstract contract BaseRouter is ReentrancyGuard, SystemAccessControl, IRouter {
  using SafeERC20 for ERC20;

  /**
   * @dev Contains an address of an ERC-20 and the balance the router holds
   * at a given moment of the transaction (ref. `_tokensToCheck`).
   */
  struct Snapshot {
    address token;
    uint256 balance;
  }

  /**
   * @dev Struct used internally containing the arguments of a IRouter.Action.Permit* to store
   * and pass in memory and avoid "stack too deep" errors.
   */
  struct PermitArgs {
    IVaultPermissions vault;
    address owner;
    address receiver;
    uint256 amount;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  struct BundleStore {
    uint256 len;
    /**
     * @dev Operations in the bundle should "benefit" or be executed
     * on behalf of this account. These are receivers on DEPOSIT and PAYBACK
     * or owners on WITHDRAW and BORROW.
     */
    address beneficiary;
    /**
     * @dev Hash generated during execution of "_bundleInternal()" that should
     * match the signed permit.
     * This argument is used in {VaultPermissions-PermitWithdraw} and
     * {VaultPermissions-PermitBorrow}
     */
    bytes32 actionArgsHash;
    uint256 nativeBalance;
    Snapshot[] tokensToCheck;
  }

  /**
   * @dev Emitted when `caller` is updated according to `allowed` boolean
   * to perform cross-chain calls.
   *
   * @param caller permitted for cross-chain calls
   * @param allowed boolean state
   */
  event AllowCaller(address caller, bool allowed);

  /// @dev Custom Errors
  error BaseRouter__bundleInternal_notFirstAction();
  error BaseRouter__bundleInternal_paramsMismatch();
  error BaseRouter__bundleInternal_flashloanInvalidRequestor();
  error BaseRouter__bundleInternal_noBalanceChange();
  error BaseRouter__bundleInternal_notBeneficiary();
  error BaseRouter__checkVaultInput_notActiveVault();
  error BaseRouter__bundleInternal_notAllowedSwapper();
  error BaseRouter__checkValidFlasher_notAllowedFlasher();
  error BaseRouter__handlePermit_notPermitAction();
  error BaseRouter__safeTransferETH_transferFailed();
  error BaseRouter__receive_senderNotWETH();
  error BaseRouter__fallback_notAllowed();
  error BaseRouter__allowCaller_noAllowChange();
  error BaseRouter__isInTokenList_snapshotLimitReached();
  error BaseRouter__xBundleFlashloan_insufficientFlashloanBalance();
  error BaseRouter__checkIfAddressZero_invalidZeroAddress();

  IWETH9 public immutable WETH9;

  bytes32 private constant ZERO_BYTES32 =
    0x0000000000000000000000000000000000000000000000000000000000000000;

  uint256 private _flashloanEnterStatus;

  /// @dev Apply it on entry cross-chain calls functions as required.
  mapping(address => bool) public isAllowedCaller;

  modifier onlyValidFlasherNonReentrant() {
    _checkValidFlasher(msg.sender);
    if (_flashloanEnterStatus == _ENTERED) {
      revert ReentrancyGuard_reentrantCall();
    }
    _flashloanEnterStatus = _ENTERED;
    _;
    _flashloanEnterStatus = _NOT_ENTERED;
  }

  /**
   * @notice Constructor of a new {BaseRouter}.
   *
   * @param weth wrapped native token of this chain
   * @param chief_ contract
   */
  constructor(IWETH9 weth, IChief chief_) payable {
    __SystemAccessControl_init(address(chief_));
    WETH9 = weth;
    _flashloanEnterStatus = _NOT_ENTERED;
  }

  /// @inheritdoc IRouter
  function xBundle(
    Action[] calldata actions,
    bytes[] calldata args
  )
    external
    payable
    override
    nonReentrant
  {
    _bundleInternal(actions, args, 0, Snapshot(address(0), 0));
  }

  /// @inheritdoc IRouter
  function xBundleFlashloan(
    Action[] calldata actions,
    bytes[] calldata args,
    address flashloanAsset,
    uint256 flashAmount
  )
    external
    payable
    override
    onlyValidFlasherNonReentrant
  {
    uint256 currentBalance = IERC20(flashloanAsset).balanceOf(address(this));
    if (currentBalance < flashAmount) {
      revert BaseRouter__xBundleFlashloan_insufficientFlashloanBalance();
    }
    _bundleInternal(actions, args, 0, Snapshot(flashloanAsset, currentBalance - flashAmount));
  }

  /**
   * @notice Marks a specific caller as allowed/disallowed to call certain functions.
   *
   * @param caller address to allow/disallow
   * @param allowed 'true' to allow, 'false' to disallow
   *
   * @dev The authorization is to be implemented on the bridge-specific contract.
   */
  function allowCaller(address caller, bool allowed) external onlyTimelock {
    _allowCaller(caller, allowed);
  }

  /// @inheritdoc IRouter
  function sweepToken(ERC20 token, address receiver) external onlyHouseKeeper {
    uint256 amount = token.balanceOf(address(this));
    if (amount == 0) return;
    token.safeTransfer(receiver, amount);
  }

  /// @inheritdoc IRouter
  function sweepETH(address receiver) external onlyHouseKeeper {
    _safeTransferETH(receiver, address(this).balance);
  }

  /**
   * @dev Executes a bundle of actions.
   * Requirements:
   * - Must not leave any balance in this contract after all actions.
   * - Must call `_checkNoBalanceChange()` after all `actions` are executed.
   * - Must call `_addTokenToList()` in `actions` that involve tokens.
   * - Must clear `_beneficiary` from storage after all `actions` are executed.
   *
   * @param actions an array of actions that will be executed in a row
   * @param args an array of encoded inputs needed to execute each action
   * @param beforeSlipped amount passed by the origin cross-chain router operation
   * @param tokenToCheck_ snapshot token balance awareness required from parent calls
   */
  function _bundleInternal(
    Action[] memory actions,
    bytes[] memory args,
    uint256 beforeSlipped,
    Snapshot memory tokenToCheck_
  )
    internal
  {
    BundleStore memory store;

    store.len = actions.length;
    if (store.len != args.length) {
      revert BaseRouter__bundleInternal_paramsMismatch();
    }

    /**
     * @dev Stores token balances of this contract at a given moment.
     * It's used to ensure there're no changes in balances at the
     * end of a transaction.
     */
    store.tokensToCheck = new Snapshot[](10);

    /// @dev Add token to check from parent calls.
    if (tokenToCheck_.token != address(0)) {
      store.tokensToCheck[0] = tokenToCheck_;
    }

    store.nativeBalance = address(this).balance - msg.value;

    for (uint256 i; i < store.len;) {
      Action action = actions[i];
      if (action == Action.Deposit) {
        // DEPOSIT
        (IVault vault, uint256 amount, address receiver, address sender) =
          abi.decode(args[i], (IVault, uint256, address, address));

        _checkVaultInput(address(vault));

        address token = vault.asset();
        store.beneficiary = _checkBeneficiary(store.beneficiary, receiver);
        _addTokenToList(token, store.tokensToCheck);
        _addTokenToList(address(vault), store.tokensToCheck);
        _safePullTokenFrom(token, sender, amount);
        _safeApprove(token, address(vault), amount);

        vault.deposit(amount, receiver);
      } else if (action == Action.Withdraw) {
        // WITHDRAW
        (bool replace, bytes memory nextArgs) = _handleWithdrawAction(actions, args, store, i);
        if (replace) args[i + 1] = nextArgs;
      } else if (action == Action.Borrow) {
        // BORROW
        (IVault vault, uint256 amount, address receiver, address owner) =
          abi.decode(args[i], (IVault, uint256, address, address));

        _checkVaultInput(address(vault));

        store.beneficiary = _checkBeneficiary(store.beneficiary, owner);
        _addTokenToList(vault.debtAsset(), store.tokensToCheck);

        vault.borrow(amount, receiver, owner);
      } else if (action == Action.Payback) {
        // PAYBACK
        (IVault vault, uint256 amount, address receiver, address sender) =
          abi.decode(args[i], (IVault, uint256, address, address));

        _checkVaultInput(address(vault));

        address token = vault.debtAsset();
        store.beneficiary = _checkBeneficiary(store.beneficiary, receiver);
        _addTokenToList(token, store.tokensToCheck);
        _safePullTokenFrom(token, sender, amount);
        _safeApprove(token, address(vault), amount);

        vault.payback(amount, receiver);
      } else if (action == Action.PermitWithdraw) {
        // PERMIT WITHDRAW
        // TODO Need to handle case in where withdraw action replaced argument.
        if (store.actionArgsHash == ZERO_BYTES32) {
          store.actionArgsHash = _getActionArgsHash(actions, args, beforeSlipped);
        }

        // Scoped code in new private function to avoid "Stack too deep"
        address owner_ = _handlePermitAction(action, args[i], store.actionArgsHash);
        store.beneficiary = _checkBeneficiary(store.beneficiary, owner_);
      } else if (action == Action.PermitBorrow) {
        // PERMIT BORROW
        // TODO Need to handle case in where withdraw action replaced argument.
        if (store.actionArgsHash == ZERO_BYTES32) {
          store.actionArgsHash = _getActionArgsHash(actions, args, beforeSlipped);
        }

        // Scoped code in new private function to avoid "Stack too deep"
        address owner_ = _handlePermitAction(action, args[i], store.actionArgsHash);
        store.beneficiary = _checkBeneficiary(store.beneficiary, owner_);
      } else if (action == Action.XTransfer) {
        // SIMPLE BRIDGE TRANSFER

        store.beneficiary = _crossTransfer(args[i], store.beneficiary);
      } else if (action == Action.XTransferWithCall) {
        // BRIDGE WITH CALLDATA

        store.beneficiary = _crossTransferWithCalldata(args[i], store.beneficiary);
      } else if (action == Action.Swap) {
        // SWAP

        if (i == 0) {
          /// @dev swap cannot be actions[0].
          revert BaseRouter__bundleInternal_notFirstAction();
        }

        store.beneficiary = _handleSwapAction(args[i], store.beneficiary, store.tokensToCheck);
      } else if (action == Action.Flashloan) {
        // FLASHLOAN

        // Decode params.
        (
          IFlasher flasher,
          address asset,
          uint256 flashAmount,
          address requestor,
          Action[] memory innerActions,
          bytes[] memory innerArgs
        ) = abi.decode(args[i], (IFlasher, address, uint256, address, Action[], bytes[]));

        _checkValidFlasher(address(flasher));

        if (requestor != address(this)) {
          revert BaseRouter__bundleInternal_flashloanInvalidRequestor();
        }
        _addTokenToList(asset, store.tokensToCheck);

        store.beneficiary =
          _checkBeneficiary(store.beneficiary, _getBeneficiaryFromCalldata(innerActions, innerArgs));

        bytes memory requestorCalldata = abi.encodeWithSelector(
          this.xBundleFlashloan.selector, innerActions, innerArgs, asset, flashAmount
        );

        // Call Flasher.
        flasher.initiateFlashloan(asset, flashAmount, requestor, requestorCalldata);
      } else if (action == Action.DepositETH) {
        uint256 amount = abi.decode(args[i], (uint256));

        ///@dev There is no check for msg.value as that is already done via `nativeBalance`
        _addTokenToList(address(WETH9), store.tokensToCheck);

        WETH9.deposit{value: amount}();
      } else if (action == Action.WithdrawETH) {
        (uint256 amount, address receiver) = abi.decode(args[i], (uint256, address));
        store.beneficiary = _checkBeneficiary(store.beneficiary, receiver);
        _addTokenToList(address(WETH9), store.tokensToCheck);

        WETH9.withdraw(amount);

        _safeTransferETH(receiver, amount);
      }
      unchecked {
        ++i;
      }
    }
    _checkNoBalanceChange(store.tokensToCheck, store.nativeBalance);
  }

  /**
   * @dev Decodes and replaces "amount" argument in args with `updateAmount`
   * in actions in where it is required to replace it.
   */
  function _replaceAmountArgInAction(
    Action action,
    bytes memory args,
    uint256 updateAmount
  )
    internal
    pure
    returns (bytes memory newArgs, uint256 previousAmount)
  {
    if (
      action == Action.Deposit || action == Action.Withdraw || action == Action.Borrow
        || action == Action.Payback
    ) {
      (IVault vault, uint256 amount, address addr1, address addr2) =
        abi.decode(args, (IVault, uint256, address, address));
      previousAmount = amount;
      newArgs = abi.encode(vault, updateAmount, addr1, addr2);
    } else if (action == Action.XTransfer || action == Action.XTransferWithCall) {
      (newArgs, previousAmount) = _replaceAmountInCrossAction(action, args, updateAmount);
    } else if (action == Action.Swap) {
      (
        ISwapper swapper,
        address assetIn,
        address assetOut,
        uint256 amountIn,
        uint256 amountOut,
        address receiver,
        address sweeper,
        uint256 minSweepOut
      ) =
        abi.decode(args, (ISwapper, address, address, uint256, uint256, address, address, uint256));
      previousAmount = amountIn;
      newArgs = abi.encode(
        swapper, assetIn, assetOut, updateAmount, amountOut, receiver, sweeper, minSweepOut
      );
    } else if (action == Action.WithdrawETH) {
      (uint256 amount, address receiver) = abi.decode(args, (uint256, address));
      previousAmount = amount;
      newArgs = abi.encode(updateAmount, receiver);
    }
  }

  /**
   * @dev Similar to `_replaceAmountArgInAction(...)` but asbtracted to implement
   * specific bridge logic.
   */
  function _replaceAmountInCrossAction(
    Action action,
    bytes memory args,
    uint256 updateAmount
  )
    internal
    pure
    virtual
    returns (bytes memory newArgs, uint256 previousAmount);

  /**
   * @dev Handles both permit actions logic flow.
   * This function was required to avoid "stack too deep" error in `_bundleInternal()`.
   *
   * @param action either IRouter.Action.PermitWithdraw (6), or IRouter.Action.PermitBorrow (7)
   * @param arg of the ongoing action
   * @param actionArgsHash_ created previously withing `_bundleInternal()` to be used in permit check
   */
  function _handlePermitAction(
    IRouter.Action action,
    bytes memory arg,
    bytes32 actionArgsHash_
  )
    private
    returns (address)
  {
    PermitArgs memory permitArgs;
    {
      (
        permitArgs.vault,
        permitArgs.owner,
        permitArgs.receiver,
        permitArgs.amount,
        permitArgs.deadline,
        permitArgs.v,
        permitArgs.r,
        permitArgs.s
      ) = abi.decode(
        arg, (IVaultPermissions, address, address, uint256, uint256, uint8, bytes32, bytes32)
      );
    }

    _checkVaultInput(address(permitArgs.vault));

    if (action == IRouter.Action.PermitWithdraw) {
      permitArgs.vault.permitWithdraw(
        permitArgs.owner,
        permitArgs.receiver,
        permitArgs.amount,
        permitArgs.deadline,
        actionArgsHash_,
        permitArgs.v,
        permitArgs.r,
        permitArgs.s
      );
    } else if (action == IRouter.Action.PermitBorrow) {
      permitArgs.vault.permitBorrow(
        permitArgs.owner,
        permitArgs.receiver,
        permitArgs.amount,
        permitArgs.deadline,
        actionArgsHash_,
        permitArgs.v,
        permitArgs.r,
        permitArgs.s
      );
    } else {
      revert BaseRouter__handlePermit_notPermitAction();
    }

    return permitArgs.owner;
  }

  /**
   * @dev Returns the `zeroPermitEncodedArgs` which is required to create
   * the `actionArgsHash` used during permit signature
   *
   * @param vault that will execute action
   * @param owner owner of the assets
   * @param receiver of the assets after action
   * @param amount of assets being permitted in action
   */
  function _getZeroPermitEncodedArgs(
    IVaultPermissions vault,
    address owner,
    address receiver,
    uint256 amount
  )
    private
    pure
    returns (bytes memory)
  {
    return abi.encode(vault, owner, receiver, amount, 0, 0, ZERO_BYTES32, ZERO_BYTES32);
  }

  /**
   * @dev Returns the `actionsArgsHash` required in
   * {VaultPermissions-permitWithdraw} or {VaultPermissions-permitBorrow}.
   * Requirements:
   * - Must replace arguments in IRouter.Action.PermitWithdraw for "zeroPermit".
   * - Must replace arguments in IRouter.Action.PermitBorrow for "zeroPermit".
   * - Must replace `beforeSlipped` amount in cross-chain txs that had slippage.
   *
   *
   * @param actions being executed in this `_bundleInternal`
   * @param args provided in `_bundleInternal`
   * @param beforeSlipped amount passed by the origin cross-chain router operation
   */
  function _getActionArgsHash(
    IRouter.Action[] memory actions,
    bytes[] memory args,
    uint256 beforeSlipped
  )
    private
    pure
    returns (bytes32)
  {
    uint256 len = actions.length;

    /**
     * @dev We intend to ONLY modify the new bytes array.
     * "memory" in solidity persists within internal calls.
     */
    bytes[] memory modArgs = new bytes[](len);
    for (uint256 i; i < len; i++) {
      modArgs[i] = args[i];
      if (
        i == 0 && beforeSlipped != 0
          && (actions[i] == IRouter.Action.Deposit || actions[i] == IRouter.Action.Payback)
      ) {
        /**
         * @dev Replace slippage values in the first ( i==0 ) "value" transfer
         * action in the destination chain (deposit or to payback).
         * If `beforeSlipped` == 0, it means there was no slippage in the attempted cross-chain tx
         * or the tx is single chain; thereore, not requiring any replacement.
         * Then, if beforeSlipped != 0 and beforeSlipped != slippedAmount, function should replace
         * to obtain the "original" intended transfer value signed in `actionArgsHash`.
         */
        (IVault vault, uint256 slippedAmount, address receiver, address sender) =
          abi.decode(modArgs[i], (IVault, uint256, address, address));
        if (beforeSlipped != slippedAmount) {
          modArgs[i] = abi.encode(vault, beforeSlipped, receiver, sender);
        }
      }
      if (actions[i] == IRouter.Action.PermitWithdraw || actions[i] == IRouter.Action.PermitBorrow)
      {
        // Need to replace permit `args` at `index` with the `zeroPermitArg`.
        (IVaultPermissions vault, address owner, address receiver, uint256 amount,,,,) = abi.decode(
          modArgs[i],
          (IVaultPermissions, address, address, uint256, uint256, uint8, bytes32, bytes32)
        );
        modArgs[i] = _getZeroPermitEncodedArgs(vault, owner, receiver, amount);
      }
    }
    return keccak256(abi.encode(actions, modArgs));
  }

  /**
   * @dev Handles withdraw actions logic flow. When there may be futher actions
   * requiring to replace the `amount` argument, it handles the replacement.
   *
   * Requirements:
   * - Check if next action is type that requires `amount` arg update otherwise
   *   proceed as normal.
   */
  function _handleWithdrawAction(
    Action[] memory actions,
    bytes[] memory args,
    BundleStore memory store,
    uint256 i
  )
    private
    returns (bool replace, bytes memory updatedArgs)
  {
    (IVault vault, uint256 amount, address receiver, address owner) =
      abi.decode(args[i], (IVault, uint256, address, address));

    _checkVaultInput(address(vault));

    store.beneficiary = _checkBeneficiary(store.beneficiary, owner);
    _addTokenToList(vault.asset(), store.tokensToCheck);
    _addTokenToList(address(vault), store.tokensToCheck);

    if (i + 1 == store.len) {
      // If Withdraw is last action just withdraw
      vault.withdraw(amount, receiver, owner);
      return (false, "");
    }

    Action nextAction = actions[i + 1];
    bytes memory nextArgs = args[i + 1];

    // Default to return same args
    updatedArgs = nextArgs;
    if (
      (
        nextAction == Action.Deposit || nextAction == Action.Swap || nextAction == Action.XTransfer
          || nextAction == Action.XTransferWithCall || nextAction == Action.WithdrawETH
      ) && receiver == address(this)
    ) {
      // Sandwhich the withrawal with bal requests to know if max-soft-withdrawal took place.
      IERC20 asset = IERC20(vault.asset());
      uint256 prevBal = asset.balanceOf(address(this));
      vault.withdraw(amount, receiver, owner);
      uint256 afterBal = asset.balanceOf(address(this));

      uint256 updateAmount = (afterBal - prevBal);

      if (amount > updateAmount) {
        replace = true;
        // If the withdraw `amount` encoded was > than the `owner`'s "maxWithdraw", the
        // difference in "(afterBal - prevBal)" must be less than amount.
        (updatedArgs,) = _replaceAmountArgInAction(nextAction, nextArgs, updateAmount);
      }
    }

    vault.withdraw(amount, receiver, owner);
  }

  /**
   * @dev Handles swap actions logic flow.
   * This function was required to avoid "stack too deep" error in `_bundleInternal()`.
   * Requirements:
   * - Must return updated "beneficiary".
   * - Must check swapper is a valid swapper at {Chief}.
   * - Must check `receiver` and `sweeper` args are the expected
   *   beneficiary when the receiver and sweeper are not address(this).
   *
   * @param arg of the ongoing action
   * @param beneficiary_ passed through `_bundleInternal()`
   * @param tokensToCheck_ passed through `_bundleInternal()`
   */
  function _handleSwapAction(
    bytes memory arg,
    address beneficiary_,
    Snapshot[] memory tokensToCheck_
  )
    private
    returns (address)
  {
    (
      ISwapper swapper,
      address assetIn,
      address assetOut,
      uint256 amountIn,
      uint256 amountOut,
      address receiver,
      address sweeper,
      uint256 minSweepOut
    ) = abi.decode(arg, (ISwapper, address, address, uint256, uint256, address, address, uint256));

    if (!chief.allowedSwapper(address(swapper))) {
      revert BaseRouter__bundleInternal_notAllowedSwapper();
    }

    _addTokenToList(assetIn, tokensToCheck_);
    _addTokenToList(assetOut, tokensToCheck_);
    _safeApprove(assetIn, address(swapper), amountIn);

    if (receiver != address(this) && !chief.allowedFlasher(receiver)) {
      beneficiary_ = _checkBeneficiary(beneficiary_, receiver);
    }

    if (sweeper != address(this)) {
      beneficiary_ = _checkBeneficiary(beneficiary_, sweeper);
    }

    swapper.swap(assetIn, assetOut, amountIn, amountOut, receiver, sweeper, minSweepOut);
    return (beneficiary_);
  }

  /**
   * @dev Helper function to transfer ETH.
   *
   * @param receiver address to receive the ETH
   * @param amount amount to be transferred
   */
  function _safeTransferETH(address receiver, uint256 amount) internal {
    if (amount == 0) return;
    _checkIfAddressZero(receiver);
    (bool success,) = receiver.call{value: amount}(new bytes(0));
    if (!success) {
      revert BaseRouter__safeTransferETH_transferFailed();
    }
  }

  /**
   * @dev Helper function to pull ERC-20 token from a sender address after some checks.
   * The checks are needed because when we bundle multiple actions
   * it can happen the router already holds the assets in question;
   * for. example when we withdraw from a vault and deposit to another one.
   *
   * @param token ERC-20 token address
   * @param sender address to pull tokens from
   * @param amount amount of tokens to be pulled
   */
  function _safePullTokenFrom(address token, address sender, uint256 amount) internal {
    if (amount == 0) return;
    if (sender != address(this) && sender == msg.sender) {
      ERC20(token).safeTransferFrom(sender, address(this), amount);
    }
  }

  /**
   * @dev Helper function to approve ERC-20 transfers.
   *
   * @param token ERC-20 address to approve
   * @param to address to approve as a spender
   * @param amount amount to be approved
   */
  function _safeApprove(address token, address to, uint256 amount) internal {
    if (amount == 0) return;
    ERC20(token).safeIncreaseAllowance(to, amount);
  }

  /**
   * @dev Check `allowCaller()` above.
   *
   * @param caller address to allow/disallow
   * @param allowed 'true' to allow, 'false' to disallow
   */
  function _allowCaller(address caller, bool allowed) internal {
    _checkIfAddressZero(caller);
    if (isAllowedCaller[caller] == allowed) {
      revert BaseRouter__allowCaller_noAllowChange();
    }
    isAllowedCaller[caller] = allowed;
    emit AllowCaller(caller, allowed);
  }

  /**
   * @dev Function to be implemented on the bridge-specific contract
   * used to transfer funds WITHOUT calldata to a destination chain.
   *
   * Note Check requirements at children contract.
   */
  function _crossTransfer(bytes memory, address beneficiary) internal virtual returns (address);

  /**
   * @dev Function to be implemented on the bridge-specific contract
   * used to transfer funds WITH calldata to a destination chain.
   *
   * Note Check requirements at children contract.
   */
  function _crossTransferWithCalldata(
    bytes memory,
    address beneficiary
  )
    internal
    virtual
    returns (address);

  /**
   * @dev Returns "true" and the `latestIndex` where a zero-address exists
   *
   * @param token address of ERC-20 to check
   * @param tokenList to check
   */
  function _isInTokenList(
    address token,
    Snapshot[] memory tokenList
  )
    private
    pure
    returns (bool value, uint256 latestIndex)
  {
    uint256 len = tokenList.length;
    for (uint256 i; i < len;) {
      if (token == tokenList[i].token) {
        return (true, 0); // leave when the element is found
      }
      if (tokenList[i].token == address(0)) {
        return (false, i); // leave if the first empty spot is found
      }
      unchecked {
        ++i;
      }
    }
    // revert if looped through whole array and found no match or empty value
    revert BaseRouter__isInTokenList_snapshotLimitReached();
  }

  /**
   * @dev Adds a token and balance to a Snapshot and returns it.
   * Requirements:
   * - Must check if token has already been added.
   *
   * @param token address of ERC-20 to be pushed
   * @param tokenList to add token
   */
  function _addTokenToList(address token, Snapshot[] memory tokenList) private view {
    (bool isInList, uint256 latestIndex) = _isInTokenList(token, tokenList);
    if (!isInList) {
      tokenList[latestIndex] = Snapshot(token, IERC20(token).balanceOf(address(this)));
    }
  }

  /**
   * @dev Checks that `erc20-balanceOf` of `_tokensToCheck` haven't change for this address.
   * Requirements:
   * - Must be called in `_bundleInternal()` at the end of all executed `actions`.
   * - Must clear `_tokensToCheck` from storage at the end of checks.
   *
   * @param tokensToCheck array of 'Snapshot' elements
   * @param nativeBalance the stored balance of ETH
   */
  function _checkNoBalanceChange(
    Snapshot[] memory tokensToCheck,
    uint256 nativeBalance
  )
    private
    view
  {
    uint256 len = tokensToCheck.length;
    for (uint256 i; i < len;) {
      if (tokensToCheck[i].token != address(0)) {
        uint256 previousBalance = tokensToCheck[i].balance;
        uint256 currentBalance = IERC20(tokensToCheck[i].token).balanceOf(address(this));

        if (currentBalance != previousBalance) {
          revert BaseRouter__bundleInternal_noBalanceChange();
        }
      } else {
        break;
      }
      unchecked {
        ++i;
      }
    }

    // Check at the end the native balance.
    if (nativeBalance != address(this).balance) {
      revert BaseRouter__bundleInternal_noBalanceChange();
    }
  }

  /**
   * @dev When bundling multiple actions assure that we act for a single beneficiary;
   * receivers on DEPOSIT and PAYBACK and owners on WITHDRAW and BORROW
   * must be the same user
   *
   * @param user address to verify is the beneficiary
   */
  function _checkBeneficiary(address beneficiary, address user) internal pure returns (address) {
    if (beneficiary == address(0)) {
      return user;
    } else if (beneficiary != user) {
      revert BaseRouter__bundleInternal_notBeneficiary();
    } else {
      return user;
    }
  }

  /**
   * @dev Extracts the beneficiary from a set of actions and args.
   * Requirements:
   * - Must be implemented in child contracts, and added to `_crossTransfer` and
   *  `crossTansferWithCalldata` as applicable.
   * - Must revert if `actions[0]` == IRouter.Action.Swap
   * - Must revert if `actions[0]` == IRouter.Action.DepositETH
   *
   * NOTE: This function is also implemented in Action.Flashloan of
   * `_internalBundle(...)`, meaning that within a flashloan
   * the Action.DepositETH cannot be the first action either.
   *
   * @param actions an array of actions that will be executed in a row
   * @param args an array of encoded inputs needed to execute each action
   */
  function _getBeneficiaryFromCalldata(
    Action[] memory actions,
    bytes[] memory args
  )
    internal
    view
    virtual
    returns (address beneficiary_);

  function _checkVaultInput(address vault_) internal view {
    if (!chief.isVaultActive(vault_)) {
      revert BaseRouter__checkVaultInput_notActiveVault();
    }
  }

  /**
   * @dev Revert if flasher is not a valid flasher at {Chief}.
   *
   * @param flasher address to check
   */
  function _checkValidFlasher(address flasher) internal view {
    if (!chief.allowedFlasher(flasher)) {
      revert BaseRouter__checkValidFlasher_notAllowedFlasher();
    }
  }

  /**
   * @dev Reverts if passed `addr` is address(0).
   */

  function _checkIfAddressZero(address addr) internal pure {
    if (addr == address(0)) {
      revert BaseRouter__checkIfAddressZero_invalidZeroAddress();
    }
  }

  /**
   * @dev Only WETH contract is allowed to transfer ETH to this address.
   * Prevent other addresses to send Ether to this contract.
   */
  receive() external payable {
    if (msg.sender != address(WETH9)) {
      revert BaseRouter__receive_senderNotWETH();
    }
  }

  /**
   * @dev Revert fallback calls.
   */
  fallback() external payable {
    revert BaseRouter__fallback_notAllowed();
  }
}