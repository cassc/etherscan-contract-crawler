// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

import "./SafeERC20.sol";

import "./IERC20.sol";
import "./ITokensRecoverable.sol";

import "./Owned.sol";

abstract contract TokensRecoverable is Owned, ITokensRecoverable {
    using SafeERC20 for IERC20;

    function recoverTokens(IERC20 token) public override ownerOnly() {
        require (canRecoverTokens(token));
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    function canRecoverTokens(IERC20 token) internal virtual view returns (bool) { 
        return address(token) != address(this); 
    }
}