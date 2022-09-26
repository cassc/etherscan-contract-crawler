// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "../interfaces/IExecutor.sol";

import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @title Executor
 * @author Connext <[email protected]>
 * @notice This library contains an `execute` function that is callabale by
 * an associated Connext contract. This is used to execute
 * arbitrary calldata on a receiving chain.
 */
contract Executor is IExecutor {
  // ============ Properties =============

  address private immutable fibswap;

  // ============ Constructor =============

  constructor(address _fibswap) {
    fibswap = _fibswap;
  }

  // ============ Modifiers =============

  /**
   * @notice Errors if the sender is not Connext
   */
  modifier onlyFibswap() {
    require(msg.sender == fibswap, "!fibswap");
    _;
  }

  // ============ Public Functions =============

  /**
   * @notice Returns the connext contract address (only address that can
   * call the `execute` function)
   * @return The address of the associated connext contract
   */
  function getFibswap() external view override returns (address) {
    return fibswap;
  }

  /**
   * @notice Executes some arbitrary call data on a given address. The
   * call data executes can be payable, and will have `amount` sent
   * along with the function (or approved to the contract). If the
   * call fails, rather than reverting, funds are sent directly to
   * some provided fallback address
   * @param _transferId Unique identifier of transaction id that necessitated
   * calldata execution
   * @param _amount The amount to approve or send with the call
   * @param _to The address to execute the calldata on
   * @param _assetId The assetId of the funds to approve to the contract or
   * send along with the call
   * @param _callData The data to execute
   */
  function execute(
    bytes32 _transferId,
    uint256 _amount,
    address payable _to,
    address payable _recovery,
    address _assetId,
    bytes calldata _callData
  ) external override onlyFibswap returns (bool) {
    // If it is not ether, approve the callTo
    // We approve here rather than transfer since many external contracts
    // simply require an approval, and it is unclear if they can handle
    // funds transferred directly to them (i.e. Uniswap)
    bool isNative = _assetId == address(0);

    // Check if the callTo is a contract
    bool success;
    if (!AddressUpgradeable.isContract(_to)) {
      _handleFailure(isNative, false, _assetId, _to, _recovery, _amount);
      // Emit event
      emit Executed(_transferId, _to, _recovery, _assetId, _amount, _callData, success);
      return success;
    }

    bool hasValue = _amount != 0;

    if (!isNative && hasValue) {
      SafeERC20Upgradeable.safeApprove(IERC20Upgradeable(_assetId), _to, 0);
      SafeERC20Upgradeable.safeIncreaseAllowance(IERC20Upgradeable(_assetId), _to, _amount);
    }

    // Try to execute the callData
    // the low level call will return `false` if its execution reverts
    (success, ) = _to.call{value: isNative ? _amount : 0}(_callData);

    // Handle failure cases
    if (!success) {
      _handleFailure(isNative, true, _assetId, _to, _recovery, _amount);
    }

    // Emit event
    emit Executed(_transferId, _to, _recovery, _assetId, _amount, _callData, success);
    return success;
  }

  function _handleFailure(
    bool isNative,
    bool hasIncreased,
    address _assetId,
    address payable _to,
    address payable _recovery,
    uint256 _amount
  ) private {
    if (_amount == 0) {
      return;
    }

    if (!isNative) {
      // Decrease allowance
      if (hasIncreased) {
        SafeERC20Upgradeable.safeDecreaseAllowance(IERC20Upgradeable(_assetId), _to, _amount);
      }
      // Transfer funds
      SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(_assetId), _recovery, _amount);
    } else {
      // Transfer funds
      AddressUpgradeable.sendValue(_recovery, _amount);
    }
  }

  receive() external payable {}
}