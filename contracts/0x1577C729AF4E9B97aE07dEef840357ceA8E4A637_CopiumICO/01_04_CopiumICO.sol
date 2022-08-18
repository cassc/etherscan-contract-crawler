// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title Copium ICO
/// The ICO for Copium Coin
/// https://www.copiumprotocol.io

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract CopiumICO is Ownable {
    uint256 public constant HARD_CAP = 50000000;

    uint256 public purchased = 0;
    uint256 public pricePer = 0;

    bool public enabled = false;
    mapping(address => uint256) public purchaseAmounts;
    address[] public purchasers;

    /**
     * Prepurchase Copium coins
     * @param amount The amount of Copium coin to purchase.
     */
    function prepurchase(uint256 amount) external payable {
        require(purchased + amount <= HARD_CAP, "CopiumICO: Invalid amount");
        require(msg.value >= amount * pricePer, "CopiumICO: Invalid ETH");
        purchasers.push(msg.sender);
        purchaseAmounts[msg.sender] += amount;
        purchased += amount;
    }

    /**
     * Sets the price.
     * @param pricePer_ The new price.
     */
    function setPrice(uint256 pricePer_) external onlyOwner {
        pricePer = pricePer_;
    }

    /**
     * Sets if the contract is enabled.
     * @param enabled_ The new status.
     */
    function setEnabled(bool enabled_) external onlyOwner {
        enabled = enabled_;
    }

    /**
     * Get the state of the contract in one call.
     * @return
     * 0: Enabled (1 or 0)
     * 1: Hard supply cap
     * 2: Purchased amount
     * 3: Price per token
     */
    function icoView() external view returns (uint256[4] memory) {
        return [enabled ? 1 : 0, HARD_CAP, purchased, pricePer];
    }

    /**
     * Withdraw contract funds to a given address.
     * @param account The account to withdraw to.
     * @param amount The amount to withdraw.
     */
    function withdraw(address payable account, uint256 amount) public virtual onlyOwner {
        Address.sendValue(account, amount);
    }
}