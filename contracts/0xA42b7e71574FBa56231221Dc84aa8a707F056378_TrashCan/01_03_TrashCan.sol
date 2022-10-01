// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TrashCan is Ownable {

    address public trashToken;
    uint256 public totalPoints;
    address payable public devWallet;

    constructor(address _token) {
        trashToken = _token;
        devWallet = payable(msg.sender);
    }

    receive() external payable {
        // Forward half the money to dev wallet
        if (devWallet != address(0)) {
            devWallet.transfer(msg.value/2);
        }
    }

    function setDevWallet(address payable _dev) public onlyOwner {
        devWallet = _dev;
    }

    // Backup function to set initial points if TrashPile.addToVault() is too expensive
    function setTotalPoints(uint256 total) public onlyOwner {
        require(totalPoints == 0, "Points already set");
        totalPoints = total;
    }

    // Burn without redeeming the vault allocation
    function emptyBurn(uint256 rarity) external {
        require(msg.sender == trashToken, "Only NFT contract can burn");
        totalPoints -= rarity;
    }

    // Burn and redeem vault allocation
    function redeemBurn(uint256 rarity, address redeemTo) external {
        require(msg.sender == trashToken, "Only NFT contract can burn");
        uint256 amountReceived = (payable(address(this)).balance * rarity) / totalPoints;
        totalPoints -= rarity;
        payable(redeemTo).transfer(amountReceived);
    }

    // Directly add an NFT's rarity points to the vault
    function addPoints(uint256 amount) external {
        require(msg.sender == trashToken, "Only NFT contract can add");
        totalPoints += amount;
    }
}