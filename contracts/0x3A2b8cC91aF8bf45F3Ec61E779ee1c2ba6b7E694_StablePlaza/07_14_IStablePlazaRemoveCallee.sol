// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "IERC20.sol";

interface IStablePlazaRemoveCallee {
   /**
    * @notice Called to `msg.sender` after executing a swap via IStablePlaza#swap.
    * @dev By the end of this callback the LP tokens owed should have been burnt.
    * @param outputToken The token that is credited to the caller.
    * @param outputAmount Amount of output tokens credited to the requested address.
    * @param LPtoBurn Amount of LP tokens that should be burnt to pay for the trade.
    * @param data Any data passed through by the caller via the IStablePlaza#addLiquidity call
    */
    function stablePlazaRemoveCall(IERC20 outputToken, uint256 outputAmount, uint256 LPtoBurn, bytes calldata data) external;
}