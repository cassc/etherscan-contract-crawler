// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '../SwapAdapter.sol';

abstract contract TakeAndRunSwap is SwapAdapter {
  /// @notice The parameters to execute the call
  struct TakeAndRunSwapParams {
    // The swapper that will execute the call
    address swapper;
    // The account that needs to be approved for token transfers
    address allowanceTarget;
    // The actual swap execution
    bytes swapData;
    // The token that will be swapped
    address tokenIn;
    // The max amount of "token in" that can be spent
    uint256 maxAmountIn;
    // Determine if we need to check if there are any unspent "token in" to return to the caller
    bool checkUnspentTokensIn;
  }

  /**
   * @notice Takes tokens from the caller, and executes a swap with the given swapper. The swap itself
   *         should include a transfer, or the swapped tokens will be left in the contract
   * @dev This function can only be executed with swappers that are allowlisted
   * @param _parameters The parameters for the swap
   */
  function takeAndRunSwap(TakeAndRunSwapParams calldata _parameters) public payable virtual onlyAllowlisted(_parameters.swapper) {
    if (_parameters.tokenIn != PROTOCOL_TOKEN) {
      _takeFromMsgSender(IERC20(_parameters.tokenIn), _parameters.maxAmountIn);
      _maxApproveSpenderIfNeeded(
        IERC20(_parameters.tokenIn),
        _parameters.allowanceTarget,
        _parameters.swapper == _parameters.allowanceTarget, // If target is a swapper, then it's ok as allowance target
        _parameters.maxAmountIn
      );
      _executeSwap(_parameters.swapper, _parameters.swapData, 0);
    } else {
      _executeSwap(_parameters.swapper, _parameters.swapData, _parameters.maxAmountIn);
    }
    if (_parameters.checkUnspentTokensIn) {
      _sendBalanceOnContractToRecipient(_parameters.tokenIn, msg.sender);
    }
  }
}