// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../PrimeRewards.sol";

error PrimeRewardsWrapper__PeriodNotSet();
error PrimeRewardsWrapper__InvalidInputs();
error PrimeRewardsWrapper__InvalidAddressTransfer();

contract PrimeRewardsWrapper is Ownable {
    PrimeRewards public primeRewards;

    constructor(address _primeRewardsAddress) {
        primeRewards = PrimeRewards(_primeRewardsAddress);
    }

    /// @notice Sets new prime token address
    /// @param _prime The PRIME token contract address.
    function setPrimeTokenAddress(IERC20 _prime) external onlyOwner {
        primeRewards.setPrimeTokenAddress(_prime);
    }

    /// @notice Sets new max number of pools. New max cannot be less than
    /// current number of pools.
    /// @param _maxNumPools The new max number of pools.
    function setMaxNumPools(uint256 _maxNumPools) external onlyOwner {
        primeRewards.setMaxNumPools(_maxNumPools);
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
        if (!(block.timestamp < primeRewards.endTimestamp() ||
            primeRewards.endTimestamp() == 0)) {
            revert PrimeRewardsWrapper__PeriodNotSet();
        }

        primeRewards.addPool(_allocPoint, _tokenIds);
    }


    /// @notice Add multiple pools. Each pool is a new set of tokenIds as a new pool. 
    /// Can only be called by the owner. DO NOT add the same token ids more than once or rewards will be inaccurate.
    /// @param _poolAllocPoints List of Allocation Points (i.e. multiplier) of the multiple pools.
    /// @param _poolTokenIds List of okenIds for ParallelAlpha ERC1155, set of tokenIds for the multiple pools.
    function addMultiplePools(uint256[] memory _poolAllocPoints, uint256[][] memory _poolTokenIds) 
        public
        virtual
        onlyOwner
    {
        if (!(block.timestamp < primeRewards.endTimestamp() ||
            primeRewards.endTimestamp() == 0)) {
            revert PrimeRewardsWrapper__PeriodNotSet();
        }
        if (_poolAllocPoints.length != _poolTokenIds.length) {
            revert PrimeRewardsWrapper__InvalidInputs();
        }

        for (uint256 i = 0; i < _poolAllocPoints.length; ++i) {
            primeRewards.addPool(_poolAllocPoints[i], _poolTokenIds[i]);
        }
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
        primeRewards.setPrimePerSecond(
            _startTimestamp,
            _endTimestamp,
            _primeAmount
        );
    }

    /// @notice Update endTimestamp, only possible to call this when caching for
    /// a period has already begun. New endTimestamp must be in the future
    /// @param _endTimestamp New timestamp for caching period to end at
    function setEndTimestamp(uint256 _endTimestamp) external onlyOwner {
        primeRewards.setEndTimestamp(_endTimestamp);
    }

    /// @notice Function for 'Top Ups', adds additional prime to distribute for remaining time
    /// in the period.
    /// @param _addPrimeAmount Amount of Prime to add to the reward pool
    function addPrimeAmount(uint256 _addPrimeAmount) external onlyOwner {
        primeRewards.addPrimeAmount(_addPrimeAmount);
    }

    /// @notice Function for 'Top Downs', removes prime distributed for remaining time
    /// in the period.
    /// @param _removePrimeAmount Amount of Prime to remove from the remaining reward pool
    function removePrimeAmount(uint256 _removePrimeAmount) external onlyOwner {
        primeRewards.removePrimeAmount(_removePrimeAmount);
    }

    /// @notice Update the given pool's PRIME allocation point (i.e. multiplier). Only owner.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _allocPoint New allocation point (i.e. multiplier) of the pool.
    function setPoolAllocPoint(uint256 _pid, uint256 _allocPoint)
        external
        onlyOwner
    {
        primeRewards.setPoolAllocPoint(_pid, _allocPoint);
    }

    /// @notice Enable/disable caching for pools. Only owner.
    /// @param _cachingPaused boolean value to set
    function setCachingPaused(bool _cachingPaused) external onlyOwner {
        primeRewards.setCachingPaused(_cachingPaused);
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
        primeRewards.sweepERC20(erc20, to, amount);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function cacheTransferOwnership(address _newOwner) public virtual onlyOwner {
        primeRewards.transferOwnership(_newOwner);
    }

    /// @notice Disable renounceOwnership. Only callable by owner.
    function renounceOwnership() public virtual override onlyOwner {
        revert("Ownership cannot be renounced");
    }

    /**
     * @dev Prevent transferring ownership of wrapper to a contract and only
     * allow EOA.
     */
    function transferOwnership(address _newOwner) public override onlyOwner {
        uint256 size;
        assembly { size := extcodesize(_newOwner) }
        if (size > 0) { 
          revert PrimeRewardsWrapper__InvalidAddressTransfer();
        }
        super.transferOwnership(_newOwner);
    }

    function setCachingAddress(address _newCachingAddress) public virtual onlyOwner {
        primeRewards = PrimeRewards(_newCachingAddress);
    }
}