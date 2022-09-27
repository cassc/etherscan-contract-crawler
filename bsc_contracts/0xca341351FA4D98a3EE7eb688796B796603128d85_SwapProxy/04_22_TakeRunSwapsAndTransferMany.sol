// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import './Shared.sol';
import '../SwapAdapter.sol';

abstract contract TakeRunSwapsAndTransferMany is SwapAdapter {
  /// @notice The parameters to execute the call
  struct TakeRunSwapsAndTransferManyParams {
    // The token that will be taken from the caller
    address tokenIn;
    // The max amount of "token in" that can be spent
    uint256 maxAmountIn;
    // The accounts that should be approved for spending
    Allowance[] allowanceTargets;
    // The different swappers involved in the swap
    address[] swappers;
    // The different swapps to execute
    bytes[] swaps;
    // Context necessary for the swap execution
    SwapContext[] swapContext;
    // Tokens to transfer after swaps have been executed
    TransferOutBalance[] transferOutBalance;
  }

  /**
   * @notice Takes tokens from the caller, and executes many different swaps. These swaps can be chained between
   *         each other, or totally independent. After the swaps are executed, the caller can specify that tokens
   *         that remained in the contract should be sent to different recipients. These tokens could be either
   *         the result of the swaps, or unspent tokens
   * @dev This function can only be executed with swappers that are allowlisted
   * @param _parameters The parameters for the swap
   */
  function takeRunSwapsAndTransferMany(TakeRunSwapsAndTransferManyParams calldata _parameters) public payable virtual {
    if (_parameters.tokenIn != PROTOCOL_TOKEN) {
      // Take from caller
      _takeFromMsgSender(IERC20(_parameters.tokenIn), _parameters.maxAmountIn);
    }

    // Validate that all swappers are allowlisted
    for (uint256 i = 0; i < _parameters.swappers.length; ) {
      _assertSwapperIsAllowlisted(_parameters.swappers[i]);
      unchecked {
        i++;
      }
    }

    // Approve whatever is necessary
    for (uint256 i = 0; i < _parameters.allowanceTargets.length; ) {
      Allowance memory _allowance = _parameters.allowanceTargets[i];
      _maxApproveSpenderIfNeeded(_allowance.token, _allowance.allowanceTarget, false, _allowance.minAllowance);
      unchecked {
        i++;
      }
    }

    // Execute swaps
    for (uint256 i = 0; i < _parameters.swaps.length; ) {
      SwapContext memory _context = _parameters.swapContext[i];
      _executeSwap(_parameters.swappers[_context.swapperIndex], _parameters.swaps[i], _context.value);
      unchecked {
        i++;
      }
    }

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