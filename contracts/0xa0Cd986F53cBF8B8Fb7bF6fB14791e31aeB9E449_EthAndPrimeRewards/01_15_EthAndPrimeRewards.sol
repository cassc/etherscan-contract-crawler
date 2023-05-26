// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./PrimeRewards.sol";

/// @title The EthAndPrimeRewards caching contract
/// @notice Caching contract for The Core. It allows for fixed ETH
/// rewards distributed evenly across all cached tokens per second.
contract EthAndPrimeRewards is PrimeRewards {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeCast for int256;

    /// @notice Info of each Cache.
    /// `rewardDebt` The amount of ETH not entitled to the user.
    struct EthCacheInfo {
        int256 rewardDebt;
    }

    /// @notice Info of each ethPool. EthPoolInfo is independent of PoolInfo.
    /// Contains the start and end timestamps of the rewards
    struct EthPoolInfo {
        uint256 accEthPerShare; // The amount of accumulated ETH per share in wei
        uint256 allocPoint; // share of the contract's per second rewards to that pool
        uint256 lastRewardTimestamp; // last time stamp at which rewards were assigned  
    }

    /// @notice Info of each ethPool.
    EthPoolInfo[] public ethPoolInfo;

    /// @notice Eth amount distributed for given period. ethAmountPerSecond = ethAmount / (ethEndTimestamp - ethStartTimestamp)
    uint256 public ethStartTimestamp; // caching start timestamp.
    uint256 public ethEndTimestamp; // caching end timestamp.
    uint256 public ethAmount; // the amount of ETH to give out as rewards.
    uint256 public ethAmountPerSecond; // the amount of ETH to give out as rewards per second.
    uint256 public constant ethAmountPerSecondPrecision = 1e18; // ethAmountPerSecond is carried around with extra precision to reduce rounding errors

    /// @dev Total allocation points. Must be the sum of all allocation points (i.e. multipliers) in all ethPools.
    uint256 public ethTotalAllocPoint;

    /// @notice Cache info of each user that caches NFT sets.
    // ethPoolID(per set) => user address => cache info
    mapping(uint256 => mapping(address => EthCacheInfo)) public ethCacheInfo;

    /// @param _prime The PRIME token contract address.
    /// @param _parallelAlpha The Parallel Alpha contract address.
    constructor(IERC20 _prime, IERC1155 _parallelAlpha)
        PrimeRewards(_prime, _parallelAlpha)
    {}

    /// @notice Add a new tokenIds ethPool. Only owner.
    /// DO NOT add the same token id more than once or rewards will be inaccurate.
    /// @param _allocPoint Allocation Point (i.e. multiplier) of the new ethPool.
    /// @param _tokenIds TokenIds for a ParallelAlpha ERC1155 tokens.
    function addPool(uint256 _allocPoint, uint256[] memory _tokenIds)
        public
        override
        onlyOwner
    {
        // Update all pool information before adding the AllocPoint for new pool
        for (uint256 i = 0; i < ethPoolInfo.length; ++i) {
            updateEthPool(i);
        }
        ethTotalAllocPoint += _allocPoint;
        ethPoolInfo.push(
            EthPoolInfo({
                accEthPerShare: 0,
                allocPoint: _allocPoint,
                lastRewardTimestamp: Math.max(
                    block.timestamp,
                    ethStartTimestamp
                )
            })
        );

        PrimeRewards.addPool(_allocPoint, _tokenIds);
        emit LogPoolSetAllocPoint(
            ethPoolInfo.length - 1,
            _allocPoint,
            ethTotalAllocPoint,
            ID_ETH
        );
    }

    /// @notice Set new period to distribute rewards between ethStartTimestamp and ethEndTimestamp
    /// evenly per second. ethAmountPerSecond = msg.value / (_ethEndTimestamp - _ethStartTimestamp)
    /// Can only be set once any existing setEthPerSecond regime has concluded (ethEndTimestamp < block.timestamp)
    /// @param _ethStartTimestamp Timestamp for caching period start
    /// @param _ethEndTimestamp Timestamp for caching period end
    function setEthPerSecond(
        uint256 _ethStartTimestamp,
        uint256 _ethEndTimestamp
    ) external payable onlyOwner {
        require(
            _ethStartTimestamp < _ethEndTimestamp,
            "endTimestamp cant be less than startTimestamp"
        );
        require(
            block.timestamp < ethStartTimestamp ||
                ethEndTimestamp < block.timestamp,
            "Only updates after ethEndTimestamp or before ethStartTimestamp"
        );
        // Update all ethPools, ensure rewards are calculated up to this timestamp
        for (uint256 i = 0; i < ethPoolInfo.length; ++i) {
            updateEthPool(i);
            ethPoolInfo[i].lastRewardTimestamp = _ethStartTimestamp;
        }
        ethAmount = msg.value;
        ethStartTimestamp = _ethStartTimestamp;
        ethEndTimestamp = _ethEndTimestamp;
        ethAmountPerSecond =
            (msg.value * ethAmountPerSecondPrecision) /
            (_ethEndTimestamp - _ethStartTimestamp);
        emit LogSetPerSecond(
            msg.value,
            _ethStartTimestamp,
            _ethEndTimestamp,
            ID_ETH
        );
    }

    /// @notice Update ethEndTimestamp, only possible to call this when caching for
    /// a period has already begun. New ethEndTimestamp can't be in the past
    /// @param _ethEndTimestamp New timestamp for caching period to end at
    function setEthEndTimestamp(uint256 _ethEndTimestamp) external onlyOwner {
        require(
            ethStartTimestamp < block.timestamp,
            "Caching period has not started"
        );
        require(block.timestamp < _ethEndTimestamp, "invalid end timestamp");
        for (uint256 i = 0; i < ethPoolInfo.length; ++i) {
            updateEthPool(i);
        }

        // Update ethAmountPerSecond based on new ethEndTimestamp
        ethStartTimestamp = block.timestamp;
        ethEndTimestamp = _ethEndTimestamp;
        ethAmountPerSecond =
            (ethAmount * ethAmountPerSecondPrecision) /
            (ethEndTimestamp - ethStartTimestamp);
        emit EndTimestampUpdated(_ethEndTimestamp, ID_ETH);
    }

    /// @notice Function for 'Top Ups', adds additional ETH to distribute for remaining time
    /// in the period.
    function addEthAmount() external payable onlyOwner {
        require(
            ethStartTimestamp < block.timestamp &&
                block.timestamp < ethEndTimestamp,
            "Can only addEthAmount during period"
        );
        // Update all ethPools
        for (uint256 i = 0; i < ethPoolInfo.length; ++i) {
            updateEthPool(i);
        }
        // Top up current period's ETH
        ethAmount += msg.value;
        ethAmountPerSecond =
            (ethAmount * ethAmountPerSecondPrecision) /
            (ethEndTimestamp - block.timestamp);
        emit RewardIncrease(msg.value, ID_ETH);
    }

    /// @notice Function for 'Top Downs', removes additional ETH to distribute for remaining time
    /// in the period.
    /// @param _removeEthAmount Amount of ETH to remove from the remaining reward pool
    function removeEthAmount(uint256 _removeEthAmount) external onlyOwner {
        require(
            ethStartTimestamp < block.timestamp &&
                block.timestamp < ethEndTimestamp,
            "Can only removeEthAmount during period"
        );
        // Update all ethPools
        for (uint256 i = 0; i < ethPoolInfo.length; ++i) {
            updateEthPool(i);
        }
        // Top up current period's ETH
        _removeEthAmount = Math.min(_removeEthAmount, ethAmount);
        ethAmount -= _removeEthAmount;
        ethAmountPerSecond =
            (ethAmount * ethAmountPerSecondPrecision) /
            (ethEndTimestamp - block.timestamp);

        (bool sent, ) = msg.sender.call{ value: _removeEthAmount }("");
        require(sent, "Failed to send Ether");

        emit RewardDecrease(_removeEthAmount, ID_ETH);
    }

    /// @notice Update the given ethPool's ETH allocation point. Only owner.
    /// @param _pid The index of the ethPool. See `ethPoolInfo`.
    /// @param _allocPoint New Allocation Point (i.e. multiplier) of the ethPool.
    function setEthPoolAllocPoint(uint256 _pid, uint256 _allocPoint)
        external
        onlyOwner
    {
        // Update all ethPools
        for (uint256 i = 0; i < ethPoolInfo.length; ++i) {
            updateEthPool(i);
        }
        ethTotalAllocPoint =
            ethTotalAllocPoint -
            ethPoolInfo[_pid].allocPoint +
            _allocPoint;
        ethPoolInfo[_pid].allocPoint = _allocPoint;
        emit LogPoolSetAllocPoint(
            _pid,
            _allocPoint,
            ethTotalAllocPoint,
            ID_ETH
        );
    }

    /// @notice View function to see pending ETH on frontend.
    /// @param _pid The index of the ethPool. See `ethPoolInfo`.
    /// @param _user Address of user.
    /// @return pending ETH reward for a given user.
    function pendingEth(uint256 _pid, address _user)
        external
        view
        returns (uint256 pending)
    {
        PoolInfo memory pool = poolInfo[_pid];
        CacheInfo storage cache_ = cacheInfo[_pid][_user];
        EthPoolInfo memory ethPool = ethPoolInfo[_pid];
        EthCacheInfo storage ethCache = ethCacheInfo[_pid][_user];
        uint256 accEthPerShare = ethPool.accEthPerShare;
        uint256 totalSupply = pool.totalSupply;

        if (
            ethStartTimestamp <= block.timestamp &&
            ethPool.lastRewardTimestamp < block.timestamp &&
            totalSupply > 0
        ) {
            uint256 updateToTimestamp = Math.min(
                block.timestamp,
                ethEndTimestamp
            );
            uint256 seconds_ = updateToTimestamp - ethPool.lastRewardTimestamp;
            uint256 ethReward = (seconds_ *
                ethAmountPerSecond *
                ethPool.allocPoint) / ethTotalAllocPoint;
            accEthPerShare += ethReward / totalSupply;
        }
        pending =
            ((cache_.amount * accEthPerShare).toInt256() - ethCache.rewardDebt)
                .toUint256() /
            ethAmountPerSecondPrecision;
    }

    /// @notice Update reward variables for all ethPools. Be careful of gas required.
    /// @param _pids Pool IDs of all to be updated. Update all active ethPools.
    function massUpdateEthPools(uint256[] calldata _pids) external {
        uint256 len = _pids.length;
        for (uint256 i = 0; i < len; ++i) {
            updateEthPool(_pids[i]);
        }
    }

    /// @notice Update reward variables of the given ethPool.
    /// @param _pid The index of the ethPool. See `ethPoolInfo`.
    function updateEthPool(uint256 _pid) public {
        PoolInfo memory pool = poolInfo[_pid];
        EthPoolInfo storage ethPool = ethPoolInfo[_pid];
        uint256 totalSupply = pool.totalSupply;
        if (
            ethStartTimestamp > block.timestamp ||
            ethPool.lastRewardTimestamp >= block.timestamp ||
            (ethStartTimestamp == 0 && ethEndTimestamp == 0)
        ) {
            return;
        }

        uint256 updateToTimestamp = Math.min(block.timestamp, ethEndTimestamp);
        uint256 seconds_ = updateToTimestamp - ethPool.lastRewardTimestamp;
        uint256 ethReward = (seconds_ *
            ethAmountPerSecond *
            ethPool.allocPoint) / ethTotalAllocPoint;
        ethAmount -= ethReward / ethAmountPerSecondPrecision;
        if (totalSupply > 0) {
            ethPool.accEthPerShare += ethReward / totalSupply;
        }
        ethPool.lastRewardTimestamp = updateToTimestamp;
        emit LogUpdatePool(
            _pid,
            ethPool.lastRewardTimestamp,
            totalSupply,
            ethPool.accEthPerShare,
            ID_ETH
        );
    }

    /// @notice Cache tokens for ETH & PRIME allocation.
    /// @param _pid The index of the ethPool. See `ethPoolInfo`.
    /// @param _amount Amount of tokens to cache for _pid.
    function cache(uint256 _pid, uint256 _amount) public virtual override {
        require(_amount > 0, "Specify valid token amount to cache");
        updateEthPool(_pid);
        EthCacheInfo storage ethCache = ethCacheInfo[_pid][msg.sender];

        // Effects
        ethCache.rewardDebt += (_amount * ethPoolInfo[_pid].accEthPerShare)
            .toInt256();

        PrimeRewards.cache(_pid, _amount);
    }

    /// @notice Withdraw tokens.
    /// @param _pid The index of the ethPool. See `ethPoolInfo`.
    /// @param _amount amount to withdraw from the pool
    function withdraw(uint256 _pid, uint256 _amount) public virtual override {
        updateEthPool(_pid);
        EthCacheInfo storage ethCache = ethCacheInfo[_pid][msg.sender];

        // Effects
        ethCache.rewardDebt -= (_amount * ethPoolInfo[_pid].accEthPerShare)
            .toInt256();

        PrimeRewards.withdraw(_pid, _amount);
    }

    /// @notice Claim accumulated eth rewards.
    /// @param _pid The index of the ethPool. See `ethPoolInfo`.
    function claimEth(uint256 _pid) public {
        updateEthPool(_pid);
        CacheInfo storage cache_ = cacheInfo[_pid][msg.sender];
        EthCacheInfo storage ethCache = ethCacheInfo[_pid][msg.sender];

        int256 accumulatedEth = (cache_.amount *
            ethPoolInfo[_pid].accEthPerShare).toInt256();
        uint256 _pendingEth = (accumulatedEth - ethCache.rewardDebt)
            .toUint256() / ethAmountPerSecondPrecision;

        // Effects
        ethCache.rewardDebt = accumulatedEth;

        // Interactions
        if (_pendingEth != 0) {
            (bool sent, ) = msg.sender.call{ value: _pendingEth }("");
            require(sent, "Failed to send Ether");
        }

        emit Claim(msg.sender, _pid, _pendingEth, ID_ETH);
    }

    /// @notice ClaimPrime and ClaimETH a pool
    /// @param _pid Pool IDs of all to be claimed
    function claimEthAndPrime(uint256 _pid) public virtual {
        PrimeRewards.claimPrime(_pid);
        claimEth(_pid);
    }

    /// @notice ClaimPrime multiple ethPools
    /// @param _pids Pool IDs of all to be claimed
    function claimPools(uint256[] calldata _pids) external virtual {
        for (uint256 i = 0; i < _pids.length; ++i) {
            claimEthAndPrime(_pids[i]);
        }
    }

    /// @notice Withdraw and claim prime rewards, update eth reward debt so that user can claim eth after.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _amount Amount of tokenId sets to withdraw.
    function withdrawAndClaimPrime(uint256 _pid, uint256 _amount)
        public
        virtual
        override
    {
        updateEthPool(_pid);
        EthCacheInfo storage ethCache = ethCacheInfo[_pid][msg.sender];

        // Effects
        ethCache.rewardDebt -= (_amount * ethPoolInfo[_pid].accEthPerShare)
            .toInt256();

        PrimeRewards.withdrawAndClaimPrime(_pid, _amount);
    }

    /// @notice Withdraw and claim prime & eth rewards.
    /// @param _pid The index of the ethPool. See `ethPoolInfo`.
    /// @param _amount tokens amount to withdraw.
    function withdrawAndClaimEthAndPrime(uint256 _pid, uint256 _amount)
        external
        virtual
    {
        // Claim ETH
        updateEthPool(_pid);
        CacheInfo storage cache_ = cacheInfo[_pid][msg.sender];
        EthCacheInfo storage ethCache = ethCacheInfo[_pid][msg.sender];

        int256 accumulatedEth = (cache_.amount *
            ethPoolInfo[_pid].accEthPerShare).toInt256();
        uint256 _pendingEth = (accumulatedEth - ethCache.rewardDebt)
            .toUint256() / ethAmountPerSecondPrecision;

        // Effects
        ethCache.rewardDebt =
            accumulatedEth -
            (_amount * ethPoolInfo[_pid].accEthPerShare).toInt256();

        if (_pendingEth != 0) {
            (bool sent, ) = msg.sender.call{ value: _pendingEth }("");
            require(sent, "Error sending eth");
        }

        // Withdraw and claim PRIME
        PrimeRewards.withdrawAndClaimPrime(_pid, _amount);
        emit Claim(msg.sender, _pid, _pendingEth, ID_ETH);
    }

    /// @notice Withdraw and forgo rewards. EMERGENCY ONLY.
    /// @param _pid The index of the pool. See `poolInfo`.
    function emergencyWithdraw(uint256 _pid) public virtual override {
        EthCacheInfo storage ethCache = ethCacheInfo[_pid][msg.sender];

        // Effects
        ethCache.rewardDebt = 0;

        PrimeRewards.emergencyWithdraw(_pid);
    }

    /// @notice Sweep function to transfer ETH out of contract.
    /// @param to address to sweep to
    /// @param amount Amount to withdraw
    function sweepETH(address payable to, uint256 amount) public onlyOwner {
        (bool sent, ) = to.call{ value: amount }("");
        require(sent, "Failed to send Ether");
    }
}