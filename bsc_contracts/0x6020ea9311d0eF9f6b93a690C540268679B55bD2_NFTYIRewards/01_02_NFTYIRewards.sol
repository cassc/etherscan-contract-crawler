// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "hardhat/console.sol";

contract NFTYIRewards {
    mapping(address => uint256) public userRewards;

    event UserRewarded(address indexed user, uint256 amount, uint256 timestamp);

    function sendReward(address[] memory _users, uint256[] memory _rewards) public payable {
        require(_users.length == _rewards.length, "Arrays length should be equal");
        for (uint256 i = 0; i<_users.length; i++) {
            require(address(this).balance >= _rewards[i], "Low balance");
            (bool success,) = payable(_users[i]).call{value : _rewards[i]}("");
            require(success, "Payment failed");
            emit UserRewarded(
                _users[i],
                _rewards[i],
                block.timestamp
            );
        }
        if (address(this).balance>0) {
            (bool success,) = payable(msg.sender).call{value : address(this).balance}("");
            require(success, "Returning exceeds failed");
        }
    }
}