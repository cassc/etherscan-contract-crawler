// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RainVault is Ownable {
    IERC20 rain;

    event Purchase(
        uint256 amount,
        address indexed wallet
    );

    constructor(address rainAddress) {
        rain = IERC20(rainAddress);
    }

    function purchase(
        uint256 amount
    ) public 
    {   require(amount > 0, "Amount must be greater than zero");
        require(rain.balanceOf(address(msg.sender)) > amount, "Not enough RAIN in user account");
        rain.transferFrom(address(msg.sender), address(this), amount);
        emit Purchase(amount, msg.sender);
    }

    function withdrawRain(uint256 amount) public onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(rain.balanceOf(address(this)) >= amount, "Insufficient balance");
        rain.transfer(address(msg.sender), amount);
    }

}