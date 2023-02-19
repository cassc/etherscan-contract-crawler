/**
 *Submitted for verification at BscScan.com on 2023-02-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract SpinToEarn {
    IERC20 public token;
    address public owner;
    uint256 public cost;
    uint256 public reward;

    event Spin(address player, uint256 payout);

    constructor(IERC20 _token, uint256 _cost, uint256 _reward) {
        token = _token;
        owner = msg.sender;
        cost = _cost;
        reward = _reward;
    }

    function spin() external {
        require(token.balanceOf(msg.sender) >= cost, "Not enough balance to play");

        // Deduct the cost of the spin
        token.transferFrom(msg.sender, owner, cost);

        // Determine the payout for the player
        uint256 payout = calculatePayout();

        // Transfer the reward to the player
        token.transferFrom(owner, msg.sender, payout);

        emit Spin(msg.sender, payout);
    }

    function calculatePayout() internal view returns (uint256) {
        // Generate a random number between 0 and 99
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100;

        if (randomNumber < 10) {
            // Player wins 5 times the reward
            return reward * 5;
        } else if (randomNumber < 30) {
            // Player wins 2 times the reward
            return reward * 2;
        } else {
            // Player loses and gets no reward
            return 0;
        }
    }
}