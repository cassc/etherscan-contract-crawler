// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface ERC20Basic {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function transfer(address to, uint256 value) external;

    function approve(address spender, uint256 value) external;
}

contract RocketieGame is Ownable {
    ERC20Basic token;

    constructor(address _token) {
        token = ERC20Basic(_token);
    }

    function payout(address to, uint256 amount) external onlyOwner {
        uint256 usdtBalance = this.tokenBalance();
        require(usdtBalance >= amount, "Not enough tokens for payout");

        token.transfer(to, amount);
    }

    // Allow you to show how many tokens owns this smart contract
    function tokenBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
}