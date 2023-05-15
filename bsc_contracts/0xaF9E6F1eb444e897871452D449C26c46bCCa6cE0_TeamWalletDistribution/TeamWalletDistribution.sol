/**
 *Submitted for verification at BscScan.com on 2023-05-14
*/

// SPDX-License-Identifier: unlicensed
pragma solidity ^0.8.0;

contract TeamWalletDistribution {
    address payable public wallet1;
    address payable public wallet2;
    address payable public wallet3;
    address payable public wallet4;

    constructor(
        address payable _wallet1,
        address payable _wallet2,
        address payable _wallet3,
        address payable _wallet4
    ) {
        wallet1 = _wallet1;
        wallet2 = _wallet2;
        wallet3 = _wallet3;
        wallet4 = _wallet4;
    }

    function distribute() external payable {
        require(msg.value > 0, "No BNB sent");

        uint256 totalBalance = address(this).balance;
        
        uint256 wallet1Share = calculateShare(wallet1, totalBalance);
        uint256 wallet2Share = calculateShare(wallet2, totalBalance);
        uint256 wallet3Share = calculateShare(wallet3, totalBalance);
        uint256 wallet4Share = totalBalance - wallet1Share - wallet2Share - wallet3Share;

        require(wallet1Share + wallet2Share + wallet3Share + wallet4Share <= totalBalance, "Invalid share calculation");

        (bool success, ) = wallet1.call{value: wallet1Share, gas: gasleft() / 4}("");
        require(success, "Failed to send BNB to wallet1");
        (success, ) = wallet2.call{value: wallet2Share, gas: gasleft() / 4}("");
        require(success, "Failed to send BNB to wallet2");
        (success, ) = wallet3.call{value: wallet3Share, gas: gasleft() / 4}("");
        require(success, "Failed to send BNB to wallet3");
        (success, ) = wallet4.call{value: wallet4Share, gas: gasleft()}("");
        require(success, "Failed to send BNB to wallet4");
    }

    function calculateShare(address payable wallet, uint256 totalBalance) private view returns (uint256) {
        uint256 walletBalance = wallet.balance;
        uint256 share = (totalBalance * walletBalance) / totalBalance;
        // Apply a small deduction to account for gas cost
        uint256 deduction = (gasleft() * 3) / 1000;
        return share > deduction ? share - deduction : 0;
    }

    function changeWallets(
        address payable _wallet1,
        address payable _wallet2,
        address payable _wallet3,
        address payable _wallet4
    ) external {
        wallet1 = _wallet1;
        wallet2 = _wallet2;
        wallet3 = _wallet3;
        wallet4 = _wallet4;
    }
    
    // Function to receive BNB and automatically trigger distribution
    receive() external payable {
        this.distribute();
    }
}