// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./../IMYCStakingFactory.sol";
import "./../IMYCStakingPool.sol";

/// @title Flexible Staking Contract
contract FlexibleStaking is IMYCStakingPool {
    IERC20 private stakeToken;

    uint256 private rewardTokensPerSecond;
    uint256 private amountOfTokensStaked;
    uint256 private rewardAmount;
    uint256 private endTimestamp;
    uint256 private startTimestamp;

    uint256 private accRewardPerShare;
    uint256 private lastAccRewardPerShareTimestamp;
    uint256 private constant REWARDS_PRECISION = 1e12;

    address public immutable creator;
    address public immutable factory;

    struct Staker {
        uint256 amount;
        uint256 rewardDebt;
        uint256 pendingRewards; //needed for old versions support
        uint256 timestamp;
    }

    mapping(address => Staker) public stakers;

    event Withdrawal(
        address indexed staker,
        uint256 amount,
        uint256 indexed timestamp
    );
    event ClaimRewards(
        address indexed staker,
        uint256 amount,
        uint256 indexed timestamp
    );
    event Deposit(
        address indexed staker,
        uint256 amount,
        uint256 indexed timestamp
    );

    constructor(
        address _stakeToken,
        address _creator,
        uint256 _rewardTokensPerSecond,
        uint256 _startTimestamp,
        uint256 _endTimestamp
    ) {
        stakeToken = IERC20(_stakeToken);
        rewardTokensPerSecond = _rewardTokensPerSecond;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        rewardAmount =
            (_endTimestamp - _startTimestamp) *
            rewardTokensPerSecond;
        creator = _creator;
        factory = msg.sender;
    }

    /**
     * @notice Extends staking end time
     * Only creator. Requires token spend allowance.
     * @param _newEndDate New end date of staking
     */
    function extendStakingTime(uint256 _newEndDate) external {
        require(msg.sender == creator, "creator mismatch");
        require(_newEndDate > endTimestamp, "timesstamp err");
        uint256 tokenAmount = (_newEndDate - endTimestamp) *
            rewardTokensPerSecond;
        stakeToken.transferFrom(msg.sender, address(this), tokenAmount);
        endTimestamp = _newEndDate;
    }

    /**
     * @notice Allows anyone to deposit into the contract
     * @param _amount The amount to deposit to the contract
     */
    function deposit(uint256 _amount) external {
        require(_amount > 0, "amount cannot be zero");
        require(endTimestamp > block.timestamp, "only before end date");
        require(startTimestamp < block.timestamp, "only after start date");
        Staker storage staker = stakers[msg.sender];
        //1. Update accRewardPerShare and claim reward
        claimRewards();
        //3. Update user balance
        staker.amount += _amount;
        //4. Update rewardDebt
        staker.rewardDebt =
            (staker.amount * accRewardPerShare) /
            REWARDS_PRECISION;
        amountOfTokensStaked += _amount;
        stakeToken.transferFrom(msg.sender, address(this), _amount);
        staker.timestamp = block.timestamp;
        emit Deposit(msg.sender, _amount, block.timestamp);
    }

    /**
     * @notice Allows anyone to withdraw their stake from the contract and harvest their rewards alongside
     * @param _amount The amount to withdraw from the contract
     */
    function withdraw(uint256 _amount) external {
        Staker storage staker = stakers[msg.sender];
        require(staker.amount > 0, "balance is zero");
        require(staker.amount >= _amount, "amount > balance");
        claimRewards();
        staker.amount -= _amount;
        amountOfTokensStaked -= _amount;
        stakeToken.transfer(msg.sender, _amount);
        if(staker.amount == 0){
            staker.timestamp = 0;
        }
        emit Withdrawal(msg.sender, _amount, block.timestamp);
    }

    /**
     * @notice Allows anyone to harvest their staking rewards
     */
    function claimRewards() public {
        Staker storage staker = stakers[msg.sender];
        //1. Update accRewardPerShare
        updateAccRewardPerShare();
        if(staker.amount == 0) return;
        //2. Calculate user rewards to harvest
        uint256 rewardsToHarvest = ((staker.amount * accRewardPerShare) /
            REWARDS_PRECISION) - staker.rewardDebt;
        //3. Update rewardDebt
        staker.rewardDebt =
            (staker.amount * accRewardPerShare) /
            REWARDS_PRECISION;

        if (rewardsToHarvest <= 0) {
            return;
        }

        stakeToken.transfer(msg.sender, rewardsToHarvest);
        emit ClaimRewards(msg.sender, rewardsToHarvest, block.timestamp);
    }

    /**
     * @notice Allows anyone to check their rewards
     * @param _staker The staker's address
     * @return staker's unharvested rewards
     */
    function checkRewards(address _staker) external view returns (uint256) {
        Staker storage staker = stakers[_staker];
        if (staker.amount <= 0) {
            return 0;
        }
        //1. Calculate accRewardPerShareTemp
        uint256 accRewardPerShareTemp = accRewardPerShare;
        uint256 timestampMaxOrCurrent = block.timestamp < endTimestamp
            ? block.timestamp
            : endTimestamp;
        if (amountOfTokensStaked > 0) {
            uint256 timeDiff = timestampMaxOrCurrent -
                lastAccRewardPerShareTimestamp;
            uint256 rewardsPerShare = timeDiff * rewardTokensPerSecond;
            accRewardPerShareTemp =
                accRewardPerShareTemp +
                ((rewardsPerShare * REWARDS_PRECISION) / amountOfTokensStaked);
        } else {
            return 0;
        }
        //2. Calculate user rewards to harvest
        uint256 rewardsToHarvest = ((staker.amount * accRewardPerShareTemp) /
            REWARDS_PRECISION) - staker.rewardDebt;

        if (rewardsToHarvest <= 0) {
            return 0;
        }

        return rewardsToHarvest;
    }

    /**
     * @notice Used to update accRewardPerShare
     */
    function updateAccRewardPerShare() private {
        uint256 timestampMaxOrCurrent = block.timestamp < endTimestamp
            ? block.timestamp
            : endTimestamp;
        if (amountOfTokensStaked > 0) {
            uint256 timeDiff = timestampMaxOrCurrent -
                lastAccRewardPerShareTimestamp;
            uint256 rewardsPerShare = timeDiff * rewardTokensPerSecond;
            accRewardPerShare =
                accRewardPerShare +
                ((rewardsPerShare * REWARDS_PRECISION) / amountOfTokensStaked);
        }
        lastAccRewardPerShareTimestamp = timestampMaxOrCurrent;
    }

    /**
     * @notice Used to get the summary of data in the contract
     * @return token rewards per block
     * @return amount of tokens staked
     * @return accumulated reward per share
     * @return last reward block
     * @return start timestamp
     * @return end timestamp
     */
    function getSummary()
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256, address)
    {
        return (
            rewardTokensPerSecond,
            amountOfTokensStaked,
            accRewardPerShare,
            lastAccRewardPerShareTimestamp,
            startTimestamp,
            endTimestamp,
            address(stakeToken)
        );
    }

    /**
     * @notice Used to withdraw the amount of tokens from contract to protocol owner address. Unsafe function, please, use only with emergency
     * @param _tokenAddress Token address
     * @param _amount Amount to withdraw
     */
    function emergencyWithdraw(address _tokenAddress, uint256 _amount) external {
        address owner = IMYCStakingFactory(factory).owner();
        require(msg.sender == owner, "Only protocol owner");
        IERC20(_tokenAddress).transfer(owner, _amount);
    }
}