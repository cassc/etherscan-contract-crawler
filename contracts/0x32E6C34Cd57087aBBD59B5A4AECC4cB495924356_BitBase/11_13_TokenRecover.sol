// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "./Ownable.sol";

/**
 * @title TokenRecover
 * @dev Allows owner to recover any ERC20 sent into the contract
 */
contract TokenRecover is Ownable {

    /**
     * @dev Only owner can call this function
     * @param tokenAddress The token contract address
     */
    function recoverERC20(address tokenAddress) public virtual onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner(), balance);
    }
}