// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '../SwapAdapter.sol';

abstract contract RunSwap is SwapAdapter {
  /// @notice The parameters to execute the call
  struct RunSwapParams {
    // The swapper that will execute the call
    address swapper;
    // The account that needs to be approved for token transfers
    address allowanceTarget;
    // The actual swap execution
    bytes swapData;
    // The token that will be swapped
    address tokenIn;
    // The amount of "token in" that will be spent
    uint256 amountIn;
  }

  /**
   * @notice Executes a swap with the given swapper. The input tokens are expected to be on the contract before
   *         this function is executed. If the swap doesn't include a transfer, then the swapped tokens will be left
   *         on the contract
   * @dev This function can only be executed with swappers that are allowlisted
   * @param _parameters The parameters for the swap
   */
  function runSwap(RunSwapParams calldata _parameters) public payable virtual onlyAllowlisted(_parameters.swapper) {
    if (_parameters.tokenIn == PROTOCOL_TOKEN) {
      _executeSwap(_parameters.swapper, _parameters.swapData, _parameters.amountIn);
    } else {
      _maxApproveSpenderIfNeeded(
        IERC20(_parameters.tokenIn),
        _parameters.allowanceTarget,
        _parameters.swapper == _parameters.allowanceTarget, // If target is a swapper, then it's ok as allowance target
        _parameters.amountIn
      );
      _executeSwap(_parameters.swapper, _parameters.swapData, 0);
    }
  }
}