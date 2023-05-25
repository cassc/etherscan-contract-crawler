// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/// @title The PrimeRewards caching contract
/// @notice Caching for PrimeKey, PrimeSets, CatalystDrive. It allows for a fixed PRIME token
/// rewards distributed evenly across all cached tokens per second.
contract PrimeRewards is Ownable, ERC1155Holder {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeCast for int256;

    /// @notice Info of each Cache.
    /// `amount` Number of NFT sets the user has provided.
    /// `rewardDebt` The amount of PRIME the user is not eligible for either from
    ///  having already harvesting or from not caching in the past.
    struct CacheInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    /// @notice Info of each pool.
    /// Contains the weighted allocation of the reward pool
    /// as well as the ParallelAlpha tokenIds required to cache in the pool
    struct PoolInfo {
        uint256 accPrimePerShare; // The amount of accumulated PRIME per share
        uint256 allocPoint; // share of the contract's per second rewards to that pool
        uint256 lastRewardTimestamp; // last time stamp at which rewards were assigned  
        uint256[] tokenIds; // ParallelAlpha tokenIds required to cache in the pool
        uint256 totalSupply; // Total number of cached sets in pool
    }

    /// @notice Address of PRIME contract.
    IERC20 public PRIME;

    /// @notice Address of Parallel Alpha erc1155
    IERC1155 public immutable parallelAlpha;

    /// @notice Info of each pool.
    PoolInfo[] public poolInfo;

    /// @notice Cache info of each user that caches NFT sets.
    // poolID(per set) => user address => cache info
    mapping(uint256 => mapping(address => CacheInfo)) public cacheInfo;

    /// @notice Prime amount distributed for given period. primeAmountPerSecond = primeAmount / (endTimestamp - startTimestamp)
    uint256 public startTimestamp; // caching start timestamp.
    uint256 public endTimestamp; // caching end timestamp.
    uint256 public primeAmount; // the amount of PRIME to give out as rewards.
    uint256 public primeAmountPerSecond; // the amount of PRIME to give out as rewards per second.
    uint256 public constant primeAmountPerSecondPrecision = 1e18; // primeAmountPerSecond is carried around with extra precision to reduce rounding errors

    /// @dev PRIME token will be minted after this contract is deployed, but should not be changeable forever
    uint256 public primeUpdateCutoff = 1667304000;

    /// @dev Limit number of pools that can be added
    uint256 public maxNumPools = 500;

    /// @dev Total allocation points. Must be the sum of all allocation points (i.e. multipliers) in all pools.
    uint256 public totalAllocPoint;

    /// @dev Caching functionality flag
    bool public cachingPaused;

    /// @dev Constants passed into event data
    uint256 public constant ID_PRIME = 0;
    uint256 public constant ID_ETH = 1;

    /// @dev internal lock for receiving ERC1155 tokens. Only allow during cache calls
    bool public onReceiveLocked = true;

     // @dev Fire when user has cached an asset (or set of assets) to the contract
    // @param user Address that has cached an asset
    // @param pid Pool ID that the user has caches assets to
    // @param amount Number of assets cached
    event Cache(address indexed user, uint256 indexed pid, uint256 amount);

    // @dev Fire when user withdraws asset (or set of assets) from contract
    // @param user Address that has withdrawn an asset
    // @param pid Pool ID of the withdrawn assets
    // @param amount Number of assets withdrawn
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    // @dev Fire if an emergency withdrawal of assets occurs
    // @param user Address that has withdrawn an asset
    // @param pid Pool ID of the withdrawn assets
    // @param amount Number of assets withdrawn
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    // @dev Fire when user claims their rewards from the contract 
    // @param user Address claiming rewards
    // @param pid Pool ID from which the user has claimed rewards
    // @param amount Amount of rewards claimed
    // @param currencyId Reward currency - 1 = ETH, 2 = PRIME
    event Claim(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        uint256 indexed currencyId
    );

    // @dev Fire when a new pool is added to the contract 
    // @param pid Pool ID of the new pool
    // @param tokenIds ERC1155 token ids of pool assets
    event LogPoolAddition(uint256 indexed pid, uint256[] tokenIds);

    // @dev Fire when the end of a rewards regime has been updated 
    // @param endTimestamp New end time for a pool rewards
    // @param currencyId Reward currency - 1 = ETH, 2 = PRIME
    event EndTimestampUpdated(uint256 endTimestamp, uint256 indexed currencyID);

    // @dev Fire when additional rewards are added to a pool's rewards regime 
    // @param amount Amount of new rewards added
    // @param currencyID Reward currency - 1 = ETH, 2 = PRIME
    event RewardIncrease(uint256 amount, uint256 indexed currencyID);

    // @dev Fire when rewards are removed from a pool's rewards regime 
    // @param amount Amount of new rewards added
    // @param currencyID Reward currency - 1 = ETH, 2 = PRIME
    event RewardDecrease(uint256 amount, uint256 indexed currencyID);

    // @dev Fire when caching is paused for the contract 
    // @param cachingPaused True if caching is paused
    event CachingPaused(bool cachingPaused);

    // @dev Fire when there has been a change to the allocation points of a pool
    // @param pid Pool ID for which the allocation points have changed
    // @param totalAllocPoint the new total allocation points of all pools
    // @param currencyID Reward currency - 1 = ETH, 2 = PRIME
    event LogPoolSetAllocPoint(
        uint256 indexed pid,
        uint256 allocPoint,
        uint256 totalAllocPoint,
        uint256 indexed currencyId
    );


    // @dev Fire when rewards are recalculated in the pool
    // @param pid Pool ID for which the update occurred
    // @param lastRewardTimestamp The timestamp at which rewards have been recalculated for
    // @param supply The amount of assets staked to that pool
    // @param currencyID Reward currency - 1 = ETH, 2 = PRIME
    event LogUpdatePool(
        uint256 indexed pid,
        uint256 lastRewardTimestamp,
        uint256 supply,
        uint256 accPerShare,
        uint256 indexed currencyId
    );

    // @dev Fire when the rewards rate has been changed
    // @param amount Amount of rewards
    // @param startTimestamp Begin time of the reward period
    // @param startTimestamp End time of the reward period
    // @param currencyID Reward currency - 1 = ETH, 2 = PRIME
    event LogSetPerSecond(
        uint256 amount,
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint256 indexed currencyId
    );

    /// @param _prime The PRIME token contract address.
    /// @param _parallelAlpha The Parallel Alpha contract address.
    constructor(IERC20 _prime, IERC1155 _parallelAlpha) {
        parallelAlpha = _parallelAlpha;
        PRIME = _prime;
    }

    /// @notice Sets new prime token address
    /// @param _prime The PRIME token contract address.
    function setPrimeTokenAddress(IERC20 _prime) external onlyOwner {
        require(
            block.timestamp < primeUpdateCutoff,
            "PRIME address update window has has passed"
        );
        PRIME = _prime;
    }

    /// @notice Sets new max number of pools. New max cannot be less than
    /// current number of pools.
    /// @param _maxNumPools The new max number of pools.
    function setMaxNumPools(uint256 _maxNumPools) external onlyOwner {
        require(
            _maxNumPools >= poolLength(),
            "Can't set maxNumPools less than poolLength"
        );
        maxNumPools = _maxNumPools;
    }

    /// @notice Returns the number of pools.
    function poolLength() public view returns (uint256 pools) {
        pools = poolInfo.length;
    }

    /// @param _pid Pool to get IDs for
    function getPoolTokenIds(uint256 _pid)
        external
        view
        returns (uint256[] memory)
    {
        return poolInfo[_pid].tokenIds;
    }

    function updateAllPools() internal {
        uint256 len = poolLength();
        for (uint256 i = 0; i < len; ++i) {
            updatePool(i);
        }
    }

    /// @notice Add a new set of tokenIds as a new pool. Can only be called by the owner.
    /// DO NOT add the same token id more than once or rewards will be inaccurate.
    /// @param _allocPoint Allocation Point (i.e. multiplier) of the new pool.
    /// @param _tokenIds TokenIds for ParallelAlpha ERC1155, set of tokenIds for pool.
    function addPool(uint256 _allocPoint, uint256[] memory _tokenIds)
        public
        virtual
        onlyOwner
    {
        require(poolInfo.length < maxNumPools, "Max num pools reached");
        require(_tokenIds.length > 0, "TokenIds cannot be empty");
        require(_allocPoint > 0, "Allocation point cannot be 0 or negative");
        // Update all pool information before adding the AllocPoint for new pool
        for (uint256 i = 0; i < poolInfo.length; ++i) {
            updatePool(i);
            require(
                keccak256(abi.encodePacked(poolInfo[i].tokenIds)) !=
                    keccak256(abi.encodePacked(_tokenIds)),
                "Pool with same tokenIds exists"
            );
        }
        totalAllocPoint += _allocPoint;
        poolInfo.push(
            PoolInfo({
                accPrimePerShare: 0,
                allocPoint: _allocPoint,
                lastRewardTimestamp: Math.max(block.timestamp, startTimestamp),
                tokenIds: _tokenIds,
                totalSupply: 0
            })
        );
        emit LogPoolAddition(poolInfo.length - 1, _tokenIds);
        emit LogPoolSetAllocPoint(
            poolInfo.length - 1,
            _allocPoint,
            totalAllocPoint,
            ID_PRIME
        );
    }

    /// @notice Set new period to distribute rewards between endTimestamp-startTimestamp
    /// evenly per second. primeAmountPerSecond = _primeAmount / (_endTimestamp - _startTimestamp)
    /// Can only be set once any existing setPrimePerSecond regime has concluded (ethEndTimestamp < block.timestamp)
    /// @param _startTimestamp Timestamp for caching period to start at
    /// @param _endTimestamp Timestamp for caching period to end at
    /// @param _primeAmount Amount of Prime to distribute evenly across whole period
    function setPrimePerSecond(
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _primeAmount
    ) external onlyOwner {
        require(
            _startTimestamp < _endTimestamp,
            "endTimestamp cant be less than startTimestamp"
        );
        require(
            block.timestamp < startTimestamp || endTimestamp < block.timestamp,
            "Only updates after endTimestamp or before startTimestamp"
        );

        // Update all pools, ensure rewards are calculated up to this timestamp
        for (uint256 i = 0; i < poolInfo.length; ++i) {
            updatePool(i);
            poolInfo[i].lastRewardTimestamp = _startTimestamp;
        }
        primeAmount = _primeAmount;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        primeAmountPerSecond =
            (_primeAmount * primeAmountPerSecondPrecision) /
            (_endTimestamp - _startTimestamp);
        emit LogSetPerSecond(
            _primeAmount,
            _startTimestamp,
            _endTimestamp,
            ID_PRIME
        );
    }

    /// @notice Update endTimestamp, only possible to call this when caching for
    /// a period has already begun. New endTimestamp must be in the future
    /// @param _endTimestamp New timestamp for caching period to end at
    function setEndTimestamp(uint256 _endTimestamp) external onlyOwner {
        require(
            startTimestamp < block.timestamp,
            "caching period has not started yet"
        );
        require(block.timestamp < _endTimestamp, "invalid end timestamp");
        updateAllPools();

        // Update primeAmountPerSecond based on the new endTimestamp
        startTimestamp = block.timestamp;
        endTimestamp = _endTimestamp;
        primeAmountPerSecond =
            (primeAmount * primeAmountPerSecondPrecision) /
            (endTimestamp - startTimestamp);
        emit EndTimestampUpdated(_endTimestamp, ID_PRIME);
    }

    /// @notice Function for 'Top Ups', adds additional prime to distribute for remaining time
    /// in the period.
    /// @param _addPrimeAmount Amount of Prime to add to the reward pool
    function addPrimeAmount(uint256 _addPrimeAmount) external onlyOwner {
        require(
            startTimestamp < block.timestamp && block.timestamp < endTimestamp,
            "Can only addPrimeAmount during period"
        );
        // Update all pools
        updateAllPools();
        // Top up current period's PRIME
        primeAmount += _addPrimeAmount;
        primeAmountPerSecond =
            (primeAmount * primeAmountPerSecondPrecision) /
            (endTimestamp - block.timestamp);
        emit RewardIncrease(_addPrimeAmount, ID_PRIME);
    }

    /// @notice Function for 'Top Downs', removes prime distributed for remaining time
    /// in the period.
    /// @param _removePrimeAmount Amount of Prime to remove from the remaining reward pool
    function removePrimeAmount(uint256 _removePrimeAmount) external onlyOwner {
        require(
            startTimestamp < block.timestamp && block.timestamp < endTimestamp,
            "Can only removePrimeAmount during a period"
        );

        // Update all pools
        updateAllPools();

        // Adjust current period's PRIME
        // Using min to make sure primeAmount can only be reduced to zero
        _removePrimeAmount = Math.min(_removePrimeAmount, primeAmount);
        primeAmount -= _removePrimeAmount;
        primeAmountPerSecond =
            (primeAmount * primeAmountPerSecondPrecision) /
            (endTimestamp - block.timestamp);
        emit RewardDecrease(_removePrimeAmount, ID_PRIME);
    }

    /// @notice Update the given pool's PRIME allocation point (i.e. multiplier). Only owner.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _allocPoint New allocation point (i.e. multiplier) of the pool.
    function setPoolAllocPoint(uint256 _pid, uint256 _allocPoint)
        external
        onlyOwner
    {
        // Update all pools
        updateAllPools();
        totalAllocPoint =
            totalAllocPoint -
            poolInfo[_pid].allocPoint +
            _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        emit LogPoolSetAllocPoint(_pid, _allocPoint, totalAllocPoint, ID_PRIME);
    }

    /// @notice Enable/disable caching for pools. Only owner.
    /// @param _cachingPaused boolean value to set
    function setCachingPaused(bool _cachingPaused) external onlyOwner {
        cachingPaused = _cachingPaused;
        emit CachingPaused(cachingPaused);
    }

    /// @notice View function to see cache amounts for pools.
    /// @param _pids List of pool index ids. See `poolInfo`.
    /// @param _addresses List of user addresses.
    /// @return amounts List of cache amounts.
    function getPoolCacheAmounts(
        uint256[] calldata _pids,
        address[] calldata _addresses
    ) external view returns (uint256[] memory) {
        require(
            _pids.length == _addresses.length,
            "pids and addresses length mismatch"
        );

        uint256[] memory amounts = new uint256[](_pids.length);
        for (uint256 i = 0; i < _pids.length; ++i) {
            amounts[i] = cacheInfo[_pids[i]][_addresses[i]].amount;
        }

        return amounts;
    }

    /// @notice View function to see pending PRIME on frontend.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _user Address of user.
    /// @return pending PRIME reward for a given user.
    function pendingPrime(uint256 _pid, address _user)
        external
        view
        returns (uint256 pending)
    {
        PoolInfo memory pool = poolInfo[_pid];
        CacheInfo storage _cache = cacheInfo[_pid][_user];
        uint256 accPrimePerShare = pool.accPrimePerShare;
        uint256 totalSupply = pool.totalSupply;

        if (
            startTimestamp <= block.timestamp &&
            pool.lastRewardTimestamp < block.timestamp &&
            totalSupply > 0
        ) {
            uint256 updateToTimestamp = Math.min(block.timestamp, endTimestamp);
            uint256 seconds_ = updateToTimestamp - pool.lastRewardTimestamp;
            uint256 primeReward = (seconds_ *
                primeAmountPerSecond *
                pool.allocPoint) / totalAllocPoint;
            accPrimePerShare += primeReward / totalSupply;
        }
        pending =
            ((_cache.amount * accPrimePerShare).toInt256() - _cache.rewardDebt)
                .toUint256() /
            primeAmountPerSecondPrecision;
    }

    /// @notice Update reward variables for all pools. Be careful of gas required.
    /// @param _pids Pool IDs of all to be updated. Make sure to update all active pools.
    function massUpdatePools(uint256[] calldata _pids) external {
        uint256 len = _pids.length;
        for (uint256 i = 0; i < len; ++i) {
            updatePool(_pids[i]);
        }
    }

    /// @notice Update reward variables for the given pool.
    /// @param _pid The index of the pool. See `poolInfo`.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (
            startTimestamp > block.timestamp ||
            pool.lastRewardTimestamp >= block.timestamp ||
            (startTimestamp == 0 && endTimestamp == 0)
        ) {
            return;
        }

        uint256 updateToTimestamp = Math.min(block.timestamp, endTimestamp);
        uint256 totalSupply = pool.totalSupply;
        uint256 seconds_ = updateToTimestamp - pool.lastRewardTimestamp;
        uint256 primeReward = (seconds_ *
            primeAmountPerSecond *
            pool.allocPoint) / totalAllocPoint;
        primeAmount -= primeReward / primeAmountPerSecondPrecision;
        if (totalSupply > 0) {
            pool.accPrimePerShare += primeReward / totalSupply;
        }
        pool.lastRewardTimestamp = updateToTimestamp;
        emit LogUpdatePool(
            _pid,
            pool.lastRewardTimestamp,
            totalSupply,
            pool.accPrimePerShare,
            ID_PRIME
        );
    }

    /// @notice Cache NFTs for PRIME rewards.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _amount Amount of 'tokenIds sets' to cache for _pid.
    function cache(uint256 _pid, uint256 _amount) public virtual {
        require(!cachingPaused, "Caching is paused");
        require(_amount > 0, "Specify valid amount to cache");
        updatePool(_pid);
        CacheInfo storage _cache = cacheInfo[_pid][msg.sender];

        // Create amounts array for tokenIds BatchTransfer
        uint256[] memory amounts = new uint256[](
            poolInfo[_pid].tokenIds.length
        );
        for (uint256 i = 0; i < amounts.length; i++) {
            amounts[i] = _amount;
        }

        // Effects
        poolInfo[_pid].totalSupply += _amount;
        _cache.amount += _amount;
        _cache.rewardDebt += (_amount * poolInfo[_pid].accPrimePerShare)
            .toInt256();

        onReceiveLocked = false;
        parallelAlpha.safeBatchTransferFrom(
            msg.sender,
            address(this),
            poolInfo[_pid].tokenIds,
            amounts,
            bytes("")
        );
        onReceiveLocked = true;

        emit Cache(msg.sender, _pid, _amount);
    }

    /// @notice Withdraw from pool
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _amount Amount of tokenId sets to withdraw from the pool
    function withdraw(uint256 _pid, uint256 _amount) public virtual {
        updatePool(_pid);
        CacheInfo storage _cache = cacheInfo[_pid][msg.sender];

        // Create amounts array for tokenIds BatchTransfer
        uint256[] memory amounts = new uint256[](
            poolInfo[_pid].tokenIds.length
        );
        for (uint256 i = 0; i < amounts.length; i++) {
            amounts[i] = _amount;
        }

        // Effects
        poolInfo[_pid].totalSupply -= _amount;
        _cache.rewardDebt -= (_amount * poolInfo[_pid].accPrimePerShare)
            .toInt256();
        _cache.amount -= _amount;

        parallelAlpha.safeBatchTransferFrom(
            address(this),
            msg.sender,
            poolInfo[_pid].tokenIds,
            amounts,
            bytes("")
        );

        emit Withdraw(msg.sender, _pid, _amount);
    }

    /// @notice Claim accumulated PRIME rewards.
    /// @param _pid The index of the pool. See `poolInfo`.
    function claimPrime(uint256 _pid) public {
        updatePool(_pid);
        CacheInfo storage _cache = cacheInfo[_pid][msg.sender];
        int256 accumulatedPrime = (_cache.amount *
            poolInfo[_pid].accPrimePerShare).toInt256();
        uint256 _pendingPrime = (accumulatedPrime - _cache.rewardDebt)
            .toUint256() / primeAmountPerSecondPrecision;

        // Effects
        _cache.rewardDebt = accumulatedPrime;

        // Interactions
        if (_pendingPrime != 0) {
            PRIME.safeTransfer(msg.sender, _pendingPrime);
        }

        emit Claim(msg.sender, _pid, _pendingPrime, ID_PRIME);
    }

    /// @notice claimPrime multiple pools
    /// @param _pids Pool IDs of all to be claimed
    function claimPrimePools(uint256[] calldata _pids) external virtual {
        for (uint256 i = 0; i < _pids.length; ++i) {
            claimPrime(_pids[i]);
        }
    }

    /// @notice Withdraw and claim PRIME rewards.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _amount Amount of tokenId sets to withdraw.
    function withdrawAndClaimPrime(uint256 _pid, uint256 _amount)
        public
        virtual
    {
        updatePool(_pid);
        CacheInfo storage _cache = cacheInfo[_pid][msg.sender];
        int256 accumulatedPrime = (_cache.amount *
            poolInfo[_pid].accPrimePerShare).toInt256();
        uint256 _pendingPrime = (accumulatedPrime - _cache.rewardDebt)
            .toUint256() / primeAmountPerSecondPrecision;

        // Create amounts array for tokenIds BatchTransfer
        uint256[] memory amounts = new uint256[](
            poolInfo[_pid].tokenIds.length
        );
        for (uint256 i = 0; i < amounts.length; i++) {
            amounts[i] = _amount;
        }

        // Effects
        poolInfo[_pid].totalSupply -= _amount;
        _cache.rewardDebt =
            accumulatedPrime -
            (_amount * poolInfo[_pid].accPrimePerShare).toInt256();
        _cache.amount -= _amount;

        if (_pendingPrime != 0) {
            PRIME.safeTransfer(msg.sender, _pendingPrime);
        }

        parallelAlpha.safeBatchTransferFrom(
            address(this),
            msg.sender,
            poolInfo[_pid].tokenIds,
            amounts,
            bytes("")
        );

        emit Withdraw(msg.sender, _pid, _amount);
        emit Claim(msg.sender, _pid, _pendingPrime, ID_PRIME);
    }

    /// @notice Withdraw and forgo rewards. EMERGENCY ONLY.
    /// @param _pid The index of the pool. See `poolInfo`.
    function emergencyWithdraw(uint256 _pid) public virtual {
        CacheInfo storage _cache = cacheInfo[_pid][msg.sender];

        uint256 amount = _cache.amount;
        // Create amounts array for tokenIds BatchTransfer
        uint256[] memory amounts = new uint256[](
            poolInfo[_pid].tokenIds.length
        );
        for (uint256 i = 0; i < amounts.length; i++) {
            amounts[i] = amount;
        }

        // Effects
        poolInfo[_pid].totalSupply -= amount;
        _cache.rewardDebt = 0;
        _cache.amount = 0;

        parallelAlpha.safeBatchTransferFrom(
            address(this),
            msg.sender,
            poolInfo[_pid].tokenIds,
            amounts,
            bytes("")
        );

        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    /// @notice Sweep function to transfer erc20 tokens out of contract. Only owner.
    /// @param erc20 Token to transfer out
    /// @param to address to sweep to
    /// @param amount Amount to withdraw
    function sweepERC20(
        IERC20 erc20,
        address to,
        uint256 amount
    ) external onlyOwner {
        erc20.transfer(to, amount);
    }

    /// @notice Disable renounceOwnership. Only callable by owner.
    function renounceOwnership() public virtual override onlyOwner {
        revert("Ownership cannot be renounced");
    }

    /// @notice Revert for calls outside of cache method
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        require(onReceiveLocked == false, "onReceive is locked");
        return this.onERC1155Received.selector;
    }

    /// @notice Revert for calls outside of cache method
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        require(onReceiveLocked == false, "onReceive is locked");
        return this.onERC1155BatchReceived.selector;
    }
}