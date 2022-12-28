// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../Library/CheapSafeERC20.sol";

contract TestCheapSafeERC20
{
    function safeTransfer(IERC20 token, address to, uint256 value)
        public
    {
        CheapSafeERC20.safeTransfer(token, to, value);
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value)
        public
    {
        CheapSafeERC20.safeTransferFrom(token, from, to, value);
    }

    function safeApprove(IERC20 token, address spender, uint256 value)
        public
    {
        CheapSafeERC20.safeApprove(token, spender, value);
    }
}