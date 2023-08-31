pragma solidity ^0.8.17;

//SPDX-License-Identifier: MIT
import "OperaToken.sol";
import "OperaLendingPool.sol";
import "IERC20.sol";
import "Math.sol";

contract OperaRevenue {
    address public owner;
    event rewardsMoved(
        address account,
        uint256 amount,
        uint256 blocktime,
        bool incoming
    );
    event rewardsRequested(address account);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "only owner");
        _;
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function requestReward() external {
        emit rewardsRequested(msg.sender);
    }

    function payoutReward(
        address user,
        uint256 amount
    ) external payable onlyOwner {
        payable(user).transfer(amount);
        emit rewardsMoved(user, amount, block.timestamp, false);
    }

    function getAddressBalance(address _address) public view returns (uint256) {
        return _address.balance;
    }

    receive() external payable {}

    function recieveRewards() external payable {
        emit rewardsMoved(msg.sender, msg.value, block.timestamp, true);
    }
}