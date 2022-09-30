// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import './Shared.sol';
import '../SwapAdapter.sol';

abstract contract TakeManyRunSwapAndTransferMany is SwapAdapter {
  /// @notice The parameters to execute the call
  struct TakeManyRunSwapAndTransferManyParams {
    // The tokens (and amounts) to take from the caller
    TakeFromCaller[] takeFromCaller;
    // The account that needs to be approved for token transfers
    address allowanceTarget;
    // The swapper that will execute the call
    address swapper;
    // The actual swap execution
    bytes swapData;
    // The amount of value to transfer as part of the swap
    uint256 valueInSwap;
    // Tokens to transfer after swaps have been executed
    TransferOutBalance[] transferOutBalance;
  }

  /**
   * @notice Takes many tokens from the caller, and executes a swap. After the swap is executed, the caller
   *         can specify that tokens that remained in the contract should be sent to different recipients.
   *         These tokens could be either the result of the swap, or unspent tokens
   * @dev This function can only be executed with swappers that are allowlisted
   * @param _parameters The parameters for the swap
   */
  function takeManyRunSwapAndTransferMany(TakeManyRunSwapAndTransferManyParams calldata _parameters)
    public
    payable
    virtual
    onlyAllowlisted(_parameters.swapper)
  {
    for (uint256 i = 0; i < _parameters.takeFromCaller.length; ) {
      // Take from caller
      TakeFromCaller memory _takeFromCaller = _parameters.takeFromCaller[i];
      _takeFromMsgSender(_takeFromCaller.token, _takeFromCaller.amount);

      // Approve whatever is necessary
      _maxApproveSpenderIfNeeded(
        _takeFromCaller.token,
        _parameters.allowanceTarget,
        _parameters.allowanceTarget == _parameters.swapper,
        _takeFromCaller.amount
      );
      unchecked {
        i++;
      }
    }

    // Execute swap
    _executeSwap(_parameters.swapper, _parameters.swapData, _parameters.valueInSwap);

    // Transfer out whatever was left in the contract
    for (uint256 i = 0; i < _parameters.transferOutBalance.length; ) {
      TransferOutBalance memory _transferOutBalance = _parameters.transferOutBalance[i];
      _sendBalanceOnContractToRecipient(_transferOutBalance.token, _transferOutBalance.recipient);
      unchecked {
        i++;
      }
    }
  }
}