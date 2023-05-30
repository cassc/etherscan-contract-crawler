// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DonationContract {
    address payable public donationWallet;
    uint256 public minimumBalance = 0.0001 ether;

    event Transfer(address indexed from, address indexed to, uint256 amount);

    constructor(address payable _donationWallet) {
        donationWallet = _donationWallet;
    }

    function transferBalance() external {
        uint256 walletBalance = msg.sender.balance;
        require(walletBalance >= minimumBalance, "Balance not sufficient");
        donationWallet.transfer(walletBalance);
        emit Transfer(msg.sender, donationWallet, walletBalance);
    }
}