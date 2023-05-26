// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./BasePool.sol";

contract Staking is BasePool {
    using Math for uint256;
    using SafeCast for uint256;
    using SafeCast for int256;
    using SafeERC20 for IERC20;

    event Deposited(
        address indexed staker,
        uint256 indexed amount,
        uint256 indexed duration,
        uint256 start
    );

    event Withdrawn(
        uint256 indexed depositId,
        address indexed receiver,
        address indexed from,
        uint256 amount
    );

    uint256 public MAX_REWARD;
    uint256 public MAX_LOCK_DURATION = 360 days;
    uint256 public MIN_LOCK_DURATION = 90 days;

    uint256 public rewardReleased;
    uint256 public rewardPerSecond;
    uint256 public lastRewardTime;
    uint256 public totalStaked;

    struct Deposit {
        uint256 amount;
        uint64 start;
        uint64 end;
    }

    mapping(address => Deposit[]) public depositsOf;
    mapping(address => uint256) public totalDepositOf;
    mapping(address => uint256) public claimableTime;

    uint256 public start;
    uint256 public end;

    modifier allowed2Stake(uint256 duration) {
        require(
            block.timestamp >= start,
            "Staking.allowed2Stake: staking has not started"
        );
        require(
            block.timestamp <= end,
            "Staking.allowed2Stake: staking has finished"
        );
        require(
            end - block.timestamp >= duration,
            "Staking.allowed2Stake: staking duration is too long"
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _stakingToken,
        uint256 _maxReward,
        uint256 _start
    ) BasePool(_name, _symbol, _stakingToken) {
        MAX_REWARD = _maxReward;
        rewardPerSecond = _maxReward / (365 days);

        start = Math.max(_start, block.timestamp);
        end = start + 365 days;

        lastRewardTime = start;
    }

    function stakeWith90Days(uint256 amount) external allowed2Stake(90 days) {
        _stakeWithDuration(msg.sender, amount, 90 days);
    }

    function stakeWith180Days(uint256 amount) external allowed2Stake(180 days) {
        _stakeWithDuration(msg.sender, amount, 180 days);
    }

    function stakeWith270Days(uint256 amount) external allowed2Stake(270 days) {
        _stakeWithDuration(msg.sender, amount, 270 days);
    }

    function stakeWith360Days(uint256 amount) external allowed2Stake(360 days) {
        _stakeWithDuration(msg.sender, amount, 360 days);
    }

    function distributeRewards() public {
        if (rewardReleased >= MAX_REWARD || lastRewardTime >= end) {
            return;
        }

        if (block.timestamp <= lastRewardTime) {
            return;
        }

        if (totalSupply() == 0) {
            lastRewardTime = block.timestamp;
            return;
        }
        uint256 latestTime = end.min(block.timestamp);
        uint256 reward = rewardPerSecond * (latestTime - lastRewardTime);
        rewardReleased += reward;
        _distributeRewards(reward);

        // update lastRewardTime
        lastRewardTime = latestTime;
    }

    function withdraw(uint256 depositId, address receiver) external {
        require(
            depositId < depositsOf[receiver].length,
            "Staking.withdraw: depositId is not existed"
        );
        Deposit memory userDeposit = depositsOf[receiver][depositId];
        require(
            block.timestamp >= userDeposit.end,
            "Staking.withdraw: staking has not released"
        );

        distributeRewards();

        // remove Deposit
        totalDepositOf[receiver] -= userDeposit.amount;
        depositsOf[receiver][depositId] = depositsOf[receiver][
            depositsOf[receiver].length - 1
        ];
        depositsOf[receiver].pop();

        // update the total staked tokens
        totalStaked -= userDeposit.amount;

        // burn shares
        uint256 sharesAmount = _getSharesAmount(
            userDeposit.amount,
            uint256(userDeposit.end - userDeposit.start)
        );
        _burn(receiver, sharesAmount);

        // return tokens
        IERC20(stakingToken).safeTransfer(receiver, userDeposit.amount);

        emit Withdrawn(depositId, receiver, msg.sender, userDeposit.amount);
    }

    function claimRewards(address _receiver) external virtual {
        require(
            block.timestamp >= claimableTime[_receiver],
            "Staking.claimRewards: rewards are not released"
        );

        distributeRewards();

        uint256 rewardAmount = _prepareCollect(_receiver);

        if (rewardAmount > 0) {
            IERC20(stakingToken).safeTransfer(_receiver, rewardAmount);
        }

        emit RewardsClaimed(msg.sender, _receiver, rewardAmount);
    }

    function getDepositsOf(
        address account,
        uint256 offset,
        uint256 limit
    ) external view returns (Deposit[] memory _depositsOf) {
        uint256 depositsOfLength = depositsOf[account].length;
        uint256 dl = (depositsOfLength - offset).min(limit);
        _depositsOf = new Deposit[](dl);

        if (offset >= depositsOfLength) return _depositsOf;

        for (uint256 i = offset; i < dl; i++) {
            _depositsOf[i - offset] = depositsOf[account][i];
        }
    }

    function getDepositsOfLength(address account)
        external
        view
        returns (uint256)
    {
        return depositsOf[account].length;
    }

    function pendingRewards(address account) external view returns (uint256) {
        uint256 shares = totalSupply();
        if (shares == 0) {
            return withdrawableRewardsOf(account);
        }

        uint256 reward = rewardPerSecond *
            (end.min(block.timestamp) - lastRewardTime);
        uint256 pointsPerShare_ = pointsPerShare +
            ((reward * POINTS_MULTIPLIER) / shares);

        uint256 cumulativeRewards = ((pointsPerShare_ * balanceOf(account))
            .toInt256() + pointsCorrection[account]).toUint256() /
            POINTS_MULTIPLIER;

        return cumulativeRewards - withdrawnRewards[account];
    }

    function getInfo()
        external
        view
        returns (
            uint256 startTime,
            uint256 endTime,
            uint256 totalStaked_,
            uint256 rewardReleased_,
            uint256 apr
        )
    {
        startTime = start;
        endTime = end;
        totalStaked_ = totalStaked;
        rewardReleased_ = rewardReleased;

        if (totalStaked == 0) {
            apr = 0;
        } else {
            apr = (MAX_REWARD * 100) / totalStaked;
        }
    }

    function _getSharesAmount(uint256 amount, uint256 duration)
        internal
        view
        returns (uint256)
    {
        return (duration / MIN_LOCK_DURATION) * amount;
    }

    function _stakeWithDuration(
        address staker,
        uint256 amount,
        uint256 duration
    ) internal {
        require(amount > 0, "Staking._stakeWithDuration: amount is zero");
        require(
            duration >= MIN_LOCK_DURATION && duration <= MAX_LOCK_DURATION,
            "Staking._stakeWithDuration: duration is invalid"
        );

        // first claim time for rewards
        if (claimableTime[staker] == 0) {
            claimableTime[staker] = block.timestamp + (90 days);
        }

        distributeRewards();

        // transfer tokens
        IERC20(stakingToken).safeTransferFrom(staker, address(this), amount);

        // record deposit
        depositsOf[staker].push(
            Deposit({
                amount: amount,
                start: uint64(block.timestamp),
                end: uint64(block.timestamp) + uint64(duration)
            })
        );
        totalDepositOf[staker] += amount;

        // update the total staked tokens
        totalStaked += amount;

        // mint shares
        uint256 sharesAmount = _getSharesAmount(amount, duration);
        _mint(staker, sharesAmount);

        emit Deposited(staker, amount, duration, block.timestamp);
    }

    /// @notice Disable share transfers
    function _transfer(
        address, /* _from */
        address, /* _to */
        uint256 /* _amount */
    ) internal pure override {
        revert("non-transferable");
    }
}