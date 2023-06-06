// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LoveVendingMachine is Ownable {
    IERC20 private _token;
    uint256 private _price;

    constructor(address loveTokenAddress, uint256 price) {
        _token = IERC20(loveTokenAddress);
        _price = price;
    }

    function buyLove(uint256 loveAmount) public payable {
        require(loveAmount <= 10, "Purchase amount exceeds limit");
        require(msg.value == loveAmount * _price, "Incorrect value sent");

        uint256 balance = _token.balanceOf(address(this));
        require(loveAmount <= balance, "Not enough $love in the reserve");

        _token.transfer(msg.sender, loveAmount);
    }

    function setPrice(uint256 price) public onlyOwner {
        _price = price;
    }

    function withdrawEther(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "Not enough Ether in contract to withdraw");

        payable(owner()).transfer(amount);
    }
}