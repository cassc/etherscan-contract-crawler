// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract FlashBackLM is Ownable {
    using SafeERC20 for IERC20;

    address public immutable stakingTokenAddress;
    address public immutable rewardTokenAddress;
    uint256 public immutable minimumStakeDuration;
    uint256 public immutable maximumStakeDuration;

    uint256 public totalReservedRewards;
    uint256 public totalLockedAmount;
    address public forfeitRewardAddress = 0x8603FfE7B00CCd759f28aBfE448454A24cFba581;

    // We have opted to make the below manually updatable
    uint256 public maxAPR = 1;
    uint256 public flashInLP = 1; // The total number of Flash in the liquidity pool
    uint256 public lpTotalSupply = 1; // The total supply of LP tokens

    struct StakeStruct {
        address stakerAddress;
        uint256 stakedAmount;
        uint256 reservedReward;
        uint256 stakeStartTs;
        uint256 stakeDuration;
        bool active;
    }
    mapping(uint256 => StakeStruct) public stakes;
    uint256 public stakeCount = 0;

    event Staked(uint256 stakeId, uint256 _amount, uint256 _duration);
    event Unstaked(uint256 stakeId, uint256 _reward, uint256 _rewardForfeited);
    event ForfeitRewardAddressChange(address _forfeitRewardAddress);
    event ParameterChange(uint256 _newMaxAPR, uint256 _newFlashInLP, uint256 _newLpTotalSupply);

    constructor(
        address _stakingTokenAddress,
        address _rewardTokenAddress,
        uint256 _minimumStakeDuration,
        uint256 _maximumStakeDuration
    ) public {
        stakingTokenAddress = _stakingTokenAddress;
        rewardTokenAddress = _rewardTokenAddress;
        minimumStakeDuration = _minimumStakeDuration;
        maximumStakeDuration = _maximumStakeDuration;

        require(stakingTokenAddress != rewardTokenAddress);
    }

    function stake(
        uint256 _amount,
        uint256 _duration,
        uint256 _minimumReward
    ) external returns (uint256) {
        require(msg.sender != 0x5089722613C2cCEe071C39C59e9889641f435F15, "BLACKLISTED ADDRESS");
        require(msg.sender != 0x8603FfE7B00CCd759f28aBfE448454A24cFba581, "BLACKLISTED ADDRESS");

        uint256 reward = calculateReward(_amount, _duration);
        require(reward >= _minimumReward, "MINIMUM REWARD NOT MET");

        // Transfer tokens from user into contract
        IERC20(stakingTokenAddress).safeTransferFrom(msg.sender, address(this), _amount);

        // Reserve the reward amount
        totalReservedRewards = totalReservedRewards + reward;
        totalLockedAmount = totalLockedAmount + _amount;

        // Store stake info
        stakeCount = stakeCount + 1;
        stakes[stakeCount] = StakeStruct(msg.sender, _amount, reward, block.timestamp, _duration, true);

        emit Staked(stakeCount, _amount, _duration);

        return stakeCount;
    }

    function unstake(uint256 _stakeId) external {
        StakeStruct memory p = stakes[_stakeId];

        // Determine if the stake exists
        require(p.active == true, "INVALID STAKE");
        require(p.stakerAddress == msg.sender, "NOT OWNER OF STAKE");
        require(block.timestamp > (p.stakeStartTs + minimumStakeDuration), "DURATION < MINIMUM");

        // Determine whether stake ended or user is unstaking early
        bool unstakedEarly = (p.stakeStartTs + p.stakeDuration) > block.timestamp;

        totalReservedRewards = totalReservedRewards - p.reservedReward;
        totalLockedAmount = totalLockedAmount - p.stakedAmount;

        // Transfer back originally staked tokens and reward (if duration ended)
        if (unstakedEarly) {
            IERC20(stakingTokenAddress).safeTransfer(msg.sender, p.stakedAmount);
            IERC20(rewardTokenAddress).safeTransfer(forfeitRewardAddress, p.reservedReward);

            emit Unstaked(_stakeId, 0, p.reservedReward);
        } else {
            IERC20(stakingTokenAddress).safeTransfer(msg.sender, p.stakedAmount);
            IERC20(rewardTokenAddress).safeTransfer(msg.sender, p.reservedReward);

            emit Unstaked(_stakeId, p.reservedReward, 0);
        }

        delete stakes[_stakeId];
    }

    function calculateReward(uint256 _amount, uint256 _duration) public view returns (uint256) {
        require(_amount > 0, "INSUFFICIENT INPUT");
        require(_duration >= minimumStakeDuration, "DURATION < MINIMUM");
        require(_duration <= maximumStakeDuration, "DURATION > MAXIMUM");

        uint256 reward = ((_duration**2) * (maxAPR * _amount)) / ((10000 * (31536000 * maximumStakeDuration)));
        reward = ((flashInLP * 2) * reward) / lpTotalSupply;

        uint256 rewardsAvailable = getAvailableRewards();
        if (reward > rewardsAvailable) {
            reward = rewardsAvailable;
        }
        require(reward > 0, "INSUFFICIENT OUTPUT");

        return reward;
    }

    function setForfeitRewardAddress(address _forfeitRewardAddress) external onlyOwner {
        forfeitRewardAddress = _forfeitRewardAddress;
        emit ForfeitRewardAddressChange(_forfeitRewardAddress);
    }

    function setParameters(
        uint256 _newMaxAPR,
        uint256 _newFlashInLP,
        uint256 _newLpTotalSupply
    ) external onlyOwner {
        maxAPR = _newMaxAPR;
        flashInLP = _newFlashInLP;
        lpTotalSupply = _newLpTotalSupply;
        emit ParameterChange(_newMaxAPR, _newFlashInLP, _newLpTotalSupply);
    }

    function getAvailableRewards() public view returns (uint256) {
        return IERC20(rewardTokenAddress).balanceOf(address(this)) - totalReservedRewards;
    }
}