// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title Payable
/// @author MilkyTaste @ Ao Collaboration Ltd.
/// https://block.aocollab.tech
/// Manage payables

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./ERC2981.sol";

contract Payable is Ownable, ERC2981 {
    constructor() {
        // Set royalties
        _setRoyalties(0x91fDe5151C8C65e1744563a2FdAbA78B8995D339, 1000);
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