// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "hardhat/console.sol";
contract Staking is Ownable {
    using SafeERC20 for IERC20;

    address public token;
    address public emergencyFeeReceiver;

    uint public rewardAmount;
    uint public emergencyFee;

    bool public isEmergencyWithdrawEnabled;

    Reward[] public reward;

    mapping(address => UserInfo[]) public userInfo;

    struct Reward {
        uint timePeriod;
        uint rewardMultiplier;
        bool isDisabled;
    }

    struct UserInfo {
        uint amount;
        uint timestamp;
        uint rewardIndex;
        bool claimed;
    }

    constructor (address _token) {
        token = _token;
    }

    function deposit(uint _rewardIndex, uint _amount) external {
        require(!reward[_rewardIndex].isDisabled, "Reward is disabled");
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        userInfo[msg.sender].push(UserInfo(_amount, block.timestamp, _rewardIndex, false));
    }

    function withdraw(uint _userInfoIndex) external {
        UserInfo storage user = userInfo[msg.sender][_userInfoIndex];
        require(user.amount > 0, "Nothing to withdraw");
        require(block.timestamp > user.timestamp + reward[user.rewardIndex].timePeriod, "Time period not over");
        require(!user.claimed, "Already claimed");
        uint returnAmount = user.amount + (user.amount * reward[user.rewardIndex].rewardMultiplier / 10000);
        user.claimed = true;
        IERC20(token).safeTransfer(msg.sender, returnAmount);
    }

    function emergencyWithdraw(uint _userInfoIndex) external {
        require(isEmergencyWithdrawEnabled, "Emergency withdraw is disabled");
        UserInfo storage user = userInfo[msg.sender][_userInfoIndex];
        require(user.amount > 0, "Nothing to withdraw");
        require(!user.claimed, "Already claimed");
        user.claimed = true;
        uint fee = user.amount * emergencyFee / 10000;
        uint returnAmount = user.amount - fee;
        // console.log(user.amount, fee, returnAmount);
        IERC20(token).safeTransfer(msg.sender, returnAmount);
        IERC20(token).safeTransfer(emergencyFeeReceiver, fee);
    }

    function setRewardPeriodData(Reward[] memory _rewards) external onlyOwner {
        for (uint i = 0; i < _rewards.length; i++) {
            reward.push(_rewards[i]);
        }
    }

    function toggleReward(uint index) external onlyOwner {
        reward[index].isDisabled = !reward[index].isDisabled;
    }

    function depositRewardTokens(uint _amount) external onlyOwner {
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        rewardAmount = rewardAmount + _amount;
    }

    function toggleEmergencyWithdraw() external onlyOwner {
        isEmergencyWithdrawEnabled = !isEmergencyWithdrawEnabled;
    }

    function setAddresses(address _token) external onlyOwner {
        token = _token;
    }

    function setEmergencyData(uint _fee, address _feeReceiver) external onlyOwner {
        emergencyFee = _fee;
        emergencyFeeReceiver = _feeReceiver;
    }

    function getUserStaking(address _user) external view returns (UserInfo[] memory) {
        return userInfo[_user];
    }

    function getRewardInfo() external view returns (Reward[] memory) {
        return reward;
    }
}