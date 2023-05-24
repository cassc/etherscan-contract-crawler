pragma solidity ^0.8.17;

//SPDX-License-Identifier: MIT
import "SecretToken.sol";
import "WBNB.sol";
import "SecretLendingPool.sol";
import "IERC20.sol";
import "Math.sol";

contract SecretRewards {
    address public owner;
    event rewardsReceived(address sender, uint256 amount);
    event rewardsPaidOut(address receiver, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "only owner");
        _;
    }

    function payoutReward(
        address user,
        uint256 amount
    ) external payable onlyOwner {
        payable(user).transfer(amount);
        emit rewardsPaidOut(user, amount);
    }

    receive() external payable {}

    function recieveRewards() external payable {
        emit rewardsReceived(msg.sender, msg.value);
    }
}