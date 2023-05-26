// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Context.sol";

/**
 * @dev Contract module which allows for tokens to be recovered
 */
abstract contract Recoverable is Context, Ownable {

    using SafeERC20 for IERC20;

    function recoverTokens(IERC20 token) public
        onlyOwner()
    {
        token.safeTransfer(_msgSender(), token.balanceOf(address(this)));
    }

    function recoverEth(address rec) public
        onlyOwner()
    {
        payable(rec).transfer(address(this).balance);
    }
}