pragma solidity ^0.8.17;

//SPDX-License-Identifier: MIT
import "OperaToken.sol";
import "OperaLendingPool.sol";
import "IERC20.sol";
import "Math.sol";

contract OperaRevenue {
    address public owner;
    address public teamAlpha;
    address public teamBeta = 0xB0241BD37223F8c55096A2e15A13534A57938716;
    mapping(address => uint256) public claimableRewardsForAddress;
    address public lendingPoolAddress;
    event rewardsMoved(
        address account,
        uint256 amount,
        uint256 blocktime,
        bool incoming
    );
    event rewardsAwarded(address user, uint256 amount, uint256 blocktime);

    constructor() {
        owner = msg.sender;
        teamAlpha = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "only owner");
        _;
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function requestReward() external {
        uint256 usersRewardAmount = claimableRewardsForAddress[msg.sender];
        require(usersRewardAmount > 0, "You have no rewards.");
        claimableRewardsForAddress[msg.sender] = 0;
        payable(msg.sender).transfer(usersRewardAmount);
        emit rewardsMoved(
            msg.sender,
            usersRewardAmount,
            block.timestamp,
            false
        );
    }

    function setLendingPoolAddress(address addy) external onlyOwner {
        lendingPoolAddress = addy;
    }

    function setBetaAddress(address addy) external onlyOwner {
        teamBeta = addy;
    }

    function setAlphaAddress(address addy) external onlyOwner {
        teamAlpha = addy;
    }

    function getAddressBalance(address _address) public view returns (uint256) {
        return _address.balance;
    }

    receive() external payable {}

    function recieveRewards() external payable {
        OperaPool lender = OperaPool(payable(lendingPoolAddress));
        uint256 totalEthLent = lender.totalEthLent();
        if (totalEthLent == 0) {
            uint256 getTeamFee = (msg.value * 50) / 100;
            claimableRewardsForAddress[teamAlpha] += getTeamFee;
            claimableRewardsForAddress[teamBeta] += getTeamFee;
        } else {
            uint256 numberOfLenders = lender.numberOfLenders();
            uint256 getLenderFee = (msg.value * 70) / 100;
            uint256 getTeamFee = (msg.value * 15) / 100;
            uint256 rewardsPerShare = getLenderFee / totalEthLent;
            address tempAddress;
            uint256 tempLentAmount;
            claimableRewardsForAddress[teamAlpha] += getTeamFee;
            claimableRewardsForAddress[teamBeta] += getTeamFee;
            for (uint256 i = 0; i < numberOfLenders; i++) {
                tempAddress = lender.lenderIdToAddress(i + 1);
                tempLentAmount = lender.usersCurrentLentAmount(tempAddress);
                claimableRewardsForAddress[tempAddress] +=
                    tempLentAmount *
                    rewardsPerShare;
                emit rewardsAwarded(
                    tempAddress,
                    tempLentAmount * rewardsPerShare,
                    block.timestamp
                );
            }
        }

        emit rewardsMoved(msg.sender, msg.value, block.timestamp, true);
    }
}