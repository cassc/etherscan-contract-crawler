// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./PrimeRewards.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/// @title The TimedCacheEthAndPrimeRewards caching contract
/// @notice Caching contract for Masterpieces. It allows for a fixed PRIME token
/// rewards distributed evenly across all cached tokens per second.
contract TimedCacheEthAndPrimeRewards is PrimeRewards, ReentrancyGuard {
    /// @notice Timed Cache Info per user per pool/Masterpiece
    struct TimedCacheInfo {
        uint256 lastCacheTimestamp;
    }

    /// @notice Eth Info of each pool.
    /// Contains the total amount of Eth rewarded and total amount of Eth claimed.
    struct EthPoolInfo {
        uint256 ethReward;
        uint256 ethClaimed;
    }

    /// @notice Pool id to Masterpiece
    mapping(uint256 => EthPoolInfo) public ethPoolInfo;
    /// @notice TimedCache info for each user that caches a Masterpiece
    /// poolID(per masterpiece) => user address => timedCache info
    mapping(uint256 => mapping(address => TimedCacheInfo))
        public timedCacheInfo;

    /// @notice Minimum number of timed cache seconds per ETH
    uint256 public ethTimedCachePeriod;
    
    /// @dev Fire when eth rewards are added to a Pool Id's eth rewards
    /// @param _tokenIds The Pool Id where Eth rewards have been added 
    /// @param _ethRewards Amount of Eth rewards added to that Pool Id
    event EthRewardsAdded(uint256[] _tokenIds, uint256[] _ethRewards);


    /// @dev Fire when eth rewards are set for a Pool Id
    /// @param _tokenIds The Pool Id of Eth rewards set 
    /// @param _ethRewards Amount of Eth to be distributed as rewards
    event EthRewardsSet(uint256[] _tokenIds, uint256[] _ethRewards);

    /// @dev Fire when there has been a change made to timedCacheperiod for either 
    ///  ETH or PRIME
    /// @param timedCachePeriod Length of time in seconds that rewards will be distributed in 
    /// @param currencyId Reward currency - 1 = ETH, 2 = PRIME
    event TimedCachePeriodUpdated(
        uint256 timedCachePeriod,
        uint256 indexed currencyId
    );

    /// @param _prime The PRIME token contract address.
    /// @param _parallelAlpha The Parallel Alpha contract address.
    constructor(IERC20 _prime, IERC1155 _parallelAlpha)
        PrimeRewards(_prime, _parallelAlpha)
    {}

    /// @notice Set the timedCachePeriod
    /// @param _ethTimedCachePeriod Minimum number of timedCache seconds per ETH
    function setEthTimedCachePeriod(uint256 _ethTimedCachePeriod)
        external
        onlyOwner
    {
        ethTimedCachePeriod = _ethTimedCachePeriod;
        emit TimedCachePeriodUpdated(_ethTimedCachePeriod, ID_ETH);
    }

    /// @notice Add ETH rewards for the specified Masterpiece pools
    /// @param _pids List of specified pools/Masterpieces
    /// @param _ethRewards List of ETH values for corresponding _pids
    function addEthRewards(uint256[] memory _pids, uint256[] memory _ethRewards)
        external
        payable
        onlyOwner
    {
        require(
            _pids.length == _ethRewards.length,
            "token ids and eth rewards lengths aren't the same"
        );
        uint256 totalEthRewards = 0;
        for (uint256 i = 0; i < _pids.length; i++) {
            uint256 pid = _pids[i];
            uint256 ethReward = _ethRewards[i];
            ethPoolInfo[pid].ethReward += ethReward;
            totalEthRewards += ethReward;
        }
        require(msg.value >= totalEthRewards, "Not enough eth sent");
        emit EthRewardsAdded(_pids, _ethRewards);
    }

    /// @notice Set ETH rewards for the specified Masterpiece pools
    /// @param _pids List of specified pools/Masterpieces
    /// @param _ethRewards List of ETH values for corresponding _pids
    function setEthRewards(uint256[] memory _pids, uint256[] memory _ethRewards)
        public
        payable
        onlyOwner
    {
        require(
            _pids.length == _ethRewards.length,
            "token ids and eth rewards lengths aren't the same"
        );
        uint256 currentTotalEth = 0;
        uint256 newTotalEth = 0;
        for (uint256 i = 0; i < _pids.length; i++) {
            uint256 pid = _pids[i];
            uint256 ethReward = _ethRewards[i];
            EthPoolInfo storage _ethPoolInfo = ethPoolInfo[pid];
            // new eth reward - old eth reward
            currentTotalEth += _ethPoolInfo.ethReward;
            newTotalEth += ethReward;
            _ethPoolInfo.ethReward = ethReward;
        }
        if (newTotalEth > currentTotalEth) {
            require(
                msg.value >= (newTotalEth - currentTotalEth),
                "Not enough eth sent"
            );
        }
        emit EthRewardsSet(_pids, _ethRewards);
    }

    /// @notice View function to see pending ETH on frontend.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _user Address of user.
    /// @return pending ETH reward for a given user.
    function pendingEth(uint256 _pid, address _user)
        external
        view
        returns (uint256 pending)
    {
        CacheInfo storage _cache = cacheInfo[_pid][_user];
        EthPoolInfo storage _ethPoolInfo = ethPoolInfo[_pid];
        TimedCacheInfo storage _timedCache = timedCacheInfo[_pid][_user];

        if (_ethPoolInfo.ethClaimed < _ethPoolInfo.ethReward) {
            uint256 remainingRewards = _ethPoolInfo.ethReward -
                _ethPoolInfo.ethClaimed;

            uint256 vestedAmount = _cache.amount *
                (((block.timestamp - _timedCache.lastCacheTimestamp) *
                    1 ether) / ethTimedCachePeriod);

            pending = Math.min(vestedAmount, remainingRewards);
        }
    }

    /// @notice Cache nfts for PRIME allocation.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _amount Amount of prime sets to cache for _pid.
    function cache(uint256 _pid, uint256 _amount) public override {
        TimedCacheInfo storage _timedCache = timedCacheInfo[_pid][msg.sender];

        _timedCache.lastCacheTimestamp = block.timestamp;

        PrimeRewards.cache(_pid, _amount);
    }

    /// @notice Claim eth for transaction sender.
    /// @param _pid Token id to claim.
    function claimEth(uint256 _pid) public nonReentrant {
        CacheInfo memory _cache = cacheInfo[_pid][msg.sender];
        EthPoolInfo storage _ethPoolInfo = ethPoolInfo[_pid];
        TimedCacheInfo storage _timedCache = timedCacheInfo[_pid][msg.sender];
        require(
            _ethPoolInfo.ethClaimed < _ethPoolInfo.ethReward,
            "Already claimed all eth"
        );

        uint256 remainingRewards = _ethPoolInfo.ethReward -
            _ethPoolInfo.ethClaimed;

        uint256 vestedAmount = _cache.amount *
            (((block.timestamp - _timedCache.lastCacheTimestamp) * 1 ether) /
                ethTimedCachePeriod);

        uint256 pendingEthReward = Math.min(vestedAmount, remainingRewards);
        _ethPoolInfo.ethClaimed += pendingEthReward;
        _timedCache.lastCacheTimestamp = block.timestamp;

        if (pendingEthReward > 0) {
            (bool sent, ) = msg.sender.call{ value: pendingEthReward }("");
            require(sent, "Failed to send Ether");
        }
        emit Claim(msg.sender, _pid, pendingEthReward, ID_ETH);
    }

    /// @notice Claim eth and PRIME for transaction sender.
    /// @param _pid Pool id to claim.
    function claimPrimeAndEth(uint256 _pid) public {
        claimPrime(_pid);
        claimEth(_pid);
    }

    /// @notice Claim multiple pools
    /// @param _pids Pool IDs of all to be claimed
    function claimPoolsPrimeAndEth(uint256[] calldata _pids) external {
        for (uint256 i = 0; i < _pids.length; ++i) {
            claimPrimeAndEth(_pids[i]);
        }
    }

    /// @notice Withdraw Masterpiece and claim eth for transaction sender.
    /// @param _pid Token id to withdraw.
    /// @param _amount Amount to withdraw.
    function withdrawAndClaimEth(uint256 _pid, uint256 _amount) external {
        claimEth(_pid);
        withdraw(_pid, _amount);
    }

    /// @notice Withdraw Masterpiece and claim eth and prime for transaction sender.
    /// @param _pid Token id to withdraw.
    /// @param _amount Amount to withdraw.
    function withdrawAndClaimPrimeAndEth(uint256 _pid, uint256 _amount)
        external
    {
        claimEth(_pid);
        withdrawAndClaimPrime(_pid, _amount);
    }

    /// @notice Sweep function to transfer ETH out of contract.
    /// @param to address to sweep to
    /// @param amount Amount to withdraw
    function sweepETH(address payable to, uint256 amount) external onlyOwner {
        (bool sent, ) = to.call{ value: amount }("");
        require(sent, "Failed to send Ether");
    }
}