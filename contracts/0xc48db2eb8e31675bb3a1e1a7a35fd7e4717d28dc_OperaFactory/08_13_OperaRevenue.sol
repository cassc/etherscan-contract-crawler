pragma solidity ^0.8.17;

//SPDX-License-Identifier: MIT
import "OperaToken.sol";
import "OperaLendingPool.sol";
import "IERC20.sol";

// import "Math.sol";

contract OperaRevenue {
    address public owner;
    address public teamAlpha;
    address public teamBeta = 0xB0241BD37223F8c55096A2e15A13534A57938716;
    uint256 public revenueShareAmount;
    uint256 public lendersCut;
    uint256 public teamsCut;
    uint256 public revShareCut;
    mapping(address => uint256) public claimableRewardsForAddress;
    address public lendingPoolAddress;
    event rewardsMoved(
        address account,
        uint256 amount,
        uint256 blocktime,
        bool incoming
    );
    event rewardsAwarded(address user, uint256 amount, uint256 blocktime);

    constructor(address _lendingPool) {
        owner = msg.sender;
        teamAlpha = msg.sender;
        lendingPoolAddress = _lendingPool;
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

    function removeRevenueShare() external onlyOwner {
        uint256 amount = revenueShareAmount;
        revenueShareAmount = 0;
        payable(owner).transfer(amount);
    }

    function awardRevenue(address user) external payable onlyOwner {
        claimableRewardsForAddress[user] += msg.value;
    }

    function changeFees(
        uint256 lenders,
        uint256 team,
        uint256 revShare
    ) external payable onlyOwner {
        lendersCut = lenders;
        teamsCut = team;
        revShareCut = revShare;
        require(
            100 == lendersCut + teamsCut + teamsCut + revShareCut,
            "Fees have to equal 100%"
        );
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
            uint256 getLenderFee = (msg.value * 60) / 100;
            uint256 getTeamFee = (msg.value * 10) / 100;
            uint256 getRevenueFee = (msg.value * 20) / 100;
            uint256 rewardsPerShare = getLenderFee / totalEthLent;
            address tempAddress;
            uint256 tempLentAmount;
            claimableRewardsForAddress[teamAlpha] += getTeamFee;
            claimableRewardsForAddress[teamBeta] += getTeamFee;
            revenueShareAmount += getRevenueFee;
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