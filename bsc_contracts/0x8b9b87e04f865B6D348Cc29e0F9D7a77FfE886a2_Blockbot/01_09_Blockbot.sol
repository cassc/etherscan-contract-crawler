// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./BOTToken.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract Blockbot is Ownable {
    // BOT Token
    BOTToken botToken;

    // token price for BNB
    uint256 public tokensPerBNB = 3333333;
    bool public purchasingEnabled = true;

    // Event that log buy operation
    event BuyTokens(address buyer, uint256 amountOfBNB, uint256 amountOfTokens);
    event TransferSent(address _destAddr, uint256 _amount);

    constructor(address tokenAddress) {
        botToken = BOTToken(tokenAddress);
    }

    function settokensPerBNB(uint256 newtokensPerBNB) external onlyOwner {
        tokensPerBNB = newtokensPerBNB;
    }

    function togglePurchasing() external onlyOwner {
        purchasingEnabled = !purchasingEnabled;
    }

    /**
     * @notice Allow users to buy token
     */
    function buyTokens() public payable returns (uint256 tokenAmount) {
        require(msg.value > 0, "Send BNB to buy some tokens");

        uint256 amountToBuy;

        amountToBuy = msg.value * tokensPerBNB;

        if (_msgSender() != owner()) {
            require(purchasingEnabled, "Purchasing has not been enabled");
        }

        // check if the Vendor Contract has enough amount of tokens for the transaction
        uint256 vendorBalance = botToken.balanceOf(address(this));
        require(
            vendorBalance >= amountToBuy,
            "Vendor contract has not enough tokens in its balance"
        );

        // Transfer token to the msg.sender
        bool sent = botToken.transfer(msg.sender, amountToBuy);
        require(sent, "Failed to transfer token to user");

        // emit the event
        emit BuyTokens(msg.sender, msg.value, amountToBuy);

        return amountToBuy;
    }

    /**
     * @notice Allow the owner of the contract to withdraw
     */
    function withdraw() public onlyOwner {
        uint256 ownerBalance = address(this).balance;
        require(ownerBalance > 0, "Owner has not balance to withdraw");

        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to send user balance back to the owner");
    }

    function withdrawBOT() public onlyOwner {
        uint256 amountToWithdraw = botToken.balanceOf(address(this));
        require(amountToWithdraw > 0, "balance is low");

        bool sent = botToken.transfer(msg.sender, amountToWithdraw);
        require(sent, "Failed to send user BOT balance back to the owner");
    }
}