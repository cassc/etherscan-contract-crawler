// SPDX-License-Identifier: GNU GPLv3
pragma solidity ^0.8.1;

/*
 *  @title Wildland's RAM for tokens
 *  RAM for Bits... Makes sense? Of course :)
 *  Copyright @ Wildlands
 *  App: https://wildlands.me
 */

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BitRAM is Ownable {
    using SafeERC20 for ERC20;

    ERC20 public immutable token;

    /**
     * @param _token erc20 token address
     */
    constructor(
        ERC20 _token
    ) {
        token = _token;
    }

    /**
     * @dev Safe token transfer function, just in case if rounding error
     * @param _to destination address
     * @param _amount token amount to be transferred to address _to
     */
    function safeBitTransfer(address _to, uint256 _amount) external onlyOwner {
        uint256 bitBal = token.balanceOf(address(this));
        if (_amount > bitBal) {
            if (bitBal > 0)
                token.safeTransfer(_to, bitBal);
        } else {
            if (_amount > 0)
                token.safeTransfer(_to, _amount);
        }
    }
}