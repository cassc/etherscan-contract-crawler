// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "IERC20.sol";

interface IStablePlazaSwapCallee {
   /**
    * @notice Called to `msg.sender` after executing a swap via IStablePlaza#swap.
    * @dev By the end of this callback the tokens owed for the swap should have been payed.
    * @param outputToken The token that was credited to the requested destination.
    * @param outputAmount Amount of output tokens that was credited to the destination.
    * @param tokenToPay The token that should be used to pay for the trade.
    * @param amountToPay Minimum amount required to repay the exchange.
    * @param data Any data passed through by the caller via the IStablePlaza#swap call
    */
    function stablePlazaSwapCall(IERC20 outputToken, uint256 outputAmount, IERC20 tokenToPay, uint256 amountToPay, bytes calldata data) external;
}