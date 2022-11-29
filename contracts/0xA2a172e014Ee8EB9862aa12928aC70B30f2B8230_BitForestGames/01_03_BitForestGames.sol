//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BitForestGames is Ownable {
    uint tokenPrice;
    uint exchangeRate;

    constructor() {
        tokenPrice = 0.0005 ether;
        exchangeRate = 1 * tokenPrice;
    }

    function changeTokenPrice(uint256 _tokenPrice) public onlyOwner {
        tokenPrice = _tokenPrice;
        exchangeRate = 1 * tokenPrice;
    }

    event PurchaseTokens(uint256 amountOfTokensPurchased);

    function purchaseTokens(uint256 amount) public payable {
        require(msg.value == amount * tokenPrice, "Inusffucient payment");

        emit PurchaseTokens(amount);
    }

    function swapTokensForEth(address[] calldata clients, uint256[] calldata amounts) public onlyOwner {
        for (uint i = 0; i < clients.length; i++) {
            uint amountInEth = amounts[i] * exchangeRate / 100 ;
            (bool success, ) = clients[i].call{ value: amountInEth }("");
            require(success, "Exchange failed");
        }
    }

    function getContractBalanceEth() public view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}
}