//SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IStaking {
    struct Stake {
        uint256 amount;
        uint256 claimedReward; // how much reward was already claimed
        uint256 lockTime;
        uint256 startTime;
        uint256 claimedTime; // when stake was withdrawn (meaning no more rewards after that point)
    }

    struct UserData {
        uint256 rewardToClaim;
        uint256 totalStaked;
        StakeView[] stakes;
    }

    struct StakeView {
        uint256 amount;
        uint256 reward;
        uint256 timeLeft;
        bool stakeClaimed;
        address contractAddr;
        uint256 stakingIndex;
    }

    event Staked(address user, uint256 stakedAmount, uint256 lockTime);
    event Claimed(address user, uint256 stakedAmount, uint256 reward);
    event ClaimedReward(address user, uint256 reward);
    event ClaimedStakedAmount(address user, uint256 stakedAmount);
    event OwnerChanged(address oldOwner, address newOwner);
    event TotalRewardsEarned(uint256 rewards);

    error AddressZero();
    error TransferFailed();
    error OnlyOwnerAccess();
    error AlreadyClaimed();
    error StakeNotExist();
    error LocktimeNotPassed();
    error NotParticipated();
    error InvalidLockTime();
    error BalanceNotEnough();
    error TokensLimitReached();
    error StakingInProgress();
    error NotInTheFuture();
    error TooMuchStakes();

    function stakeTokens(uint256 _amount, uint256 _lockTime) external;

    function calculateReward(address _user, uint256 _index) external view returns (uint256);

    function claimReward(uint256 _index) external;

    function claimStakedAmount(uint256 _index) external;

    function claim(uint256 _index) external;

    function totalStaked() external view returns (uint256);

    function setOwner(address _owner) external;

    function getUserSummary(address _user) external view returns(UserData memory);

    function getStakes(address _user) external view returns (Stake[] memory);

    function getStakesLen(address _user) external view returns(uint256);
}