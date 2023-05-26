// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title Payable
/// @author MilkyTaste @ Ao Collaboration Ltd.
/// https://block.aocollab.tech
/// Manage payables

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./ERC2981.sol";

contract Payable is Ownable, ERC2981 {
    constructor() {
        // 6.5% royalties
        _setRoyalties(0xce5eFFf1f81A862Ca21eed213a40F19f95Bc2D30, 650);
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