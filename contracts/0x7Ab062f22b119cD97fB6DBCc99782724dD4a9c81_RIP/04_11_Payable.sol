// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.8;

/// @title Payable

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./ERC2981.sol";

contract Payable is Ownable, ERC2981 {
    constructor(uint256 value) {
        // Set royalties
        _setRoyalties(0x39f0ccc3261b9eAa7C536581C20688442D8F5A3a, value);
    }

    //
    // ERC2981
    //

    /**
     * Set the royalties information.
     * @param recipient recipient of the royalties.
     * @param value percentage (using 2 decimals - 10000 = 100, 0 = 0).
     */
    function setRoyalties(address recipient, uint256 value) external onlyOwner {
        require(recipient != address(0), "zero address");
        _setRoyalties(recipient, value);
    }

    //
    // Withdraw
    //

    /**
     * Withdraw contract funds to a given address.
     * @param account The account to withdraw to.
     * @param amount The amount to withdraw.
     */
    function withdraw(address payable account, uint256 amount) public virtual onlyOwner {
        Address.sendValue(account, amount);
    }
}