// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "IERC20.sol";

interface IStablePlazaAddCallee {
   /**
    * @notice Called to `msg.sender` after executing a swap via IStablePlaza#swap.
    * @dev By the end of this callback the tokens owed for the LP tokens should have been payed.
    * @param LPamount Amount of LP tokens credited to the requested address.
    * @param tokenToPay The token that should be used to pay for the LP tokens.
    * @param amountToPay The amount of tokens required to repay the exchange.
    * @param data Any data passed through by the caller via the IStablePlaza#addLiquidity call
    */
    function stablePlazaAddCall(uint256 LPamount, IERC20 tokenToPay, uint256 amountToPay, bytes calldata data) external;
}