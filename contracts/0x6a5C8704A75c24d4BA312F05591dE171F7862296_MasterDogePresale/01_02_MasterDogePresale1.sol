// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MasterDogeToken1.sol";

contract MasterDogePresale {
    MasterDogeToken public token;
    address payable public beneficiary;
    uint256 public conversionRate;

    event TokensPurchased(address indexed buyer, uint256 amount);

    constructor(address _tokenAddress, address payable _beneficiary, uint256 _conversionRate) {
        token = MasterDogeToken(_tokenAddress);
        beneficiary = _beneficiary;
        conversionRate = _conversionRate;
    }

    // Fallback function to receive Ether and send tokens
    receive() external payable {
        uint256 tokenAmount = msg.value * conversionRate;
        require(token.balanceOf(address(this)) >= tokenAmount, "Not enough tokens available");

        // Transfer tokens to the investor
        token.transfer(msg.sender, tokenAmount);
        emit TokensPurchased(msg.sender, tokenAmount);

        // Transfer received funds to the beneficiary address
        beneficiary.transfer(msg.value);
    }

    // Withdraw remaining funds in case anything fails
    function withdrawFunds() external {
        require(msg.sender == beneficiary, "Only the beneficiary can withdraw funds");
        beneficiary.transfer(address(this).balance);
    }

}
