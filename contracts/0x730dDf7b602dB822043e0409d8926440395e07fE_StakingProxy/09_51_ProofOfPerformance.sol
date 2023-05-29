// SPDX-License-Identifier: Apache 2.0

/*

 Copyright 2017-2019 RigoBlock, Rigo Investment Sagl, 2020 Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

// solhint-disable-next-line
pragma solidity 0.7.4;

import { AuthorityFace } from "../../protocol/authorities/Authority/AuthorityFace.sol";
import { IPool } from "../../utils/Pool/IPool.sol";
import { SafeMath } from "../../utils/SafeMath/SafeMath.sol";
import { ProofOfPerformanceFace } from "./ProofOfPerformanceFace.sol";
import { IDragoRegistry } from "../../protocol/DragoRegistry/IDragoRegistry.sol";
import { IStaking } from "../../staking/interfaces/IStaking.sol";


/// @title Proof of Performance - Controls parameters of inflation.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
contract ProofOfPerformance is
    SafeMath,
    ProofOfPerformanceFace
{
    address public override dragoRegistryAddress;
    address public override rigoblockDaoAddress;
    address public override authorityAddress;

    address private immutable STAKING_PROXY_ADDRESS;
    uint256 private immutable POOL_BASE = 1e6;

    mapping (address => Group) public groupByAddress;
    mapping (uint256 => uint256) private _highWaterMark;

    struct Group {
        uint256 epochReward;
        uint256 rewardRatio;
    }

    modifier onlyRigoblockDao() {
        _assertCallerIsRigoblockDao();
        _;
    }

    modifier isApprovedFactory(address _factory) {
        _assertIsApprovedFactory(_factory);
        _;
    }

    constructor(
        address _stakingProxyAddress,
        address _rigoblockDao,
        address _dragoRegistry,
        address _authorityAddress
    ) {
        STAKING_PROXY_ADDRESS = _stakingProxyAddress;
        rigoblockDaoAddress = _rigoblockDao;
        dragoRegistryAddress = _dragoRegistry;
        authorityAddress = _authorityAddress;
    }

    /// @dev Credits the pop reward to the Staking Proxy contract.
    /// @param poolId Number of the pool Id in registry.
    function creditPopRewardToStakingProxy(
        uint256 poolId
    )
        external
        override
    {
        (address poolAddress, , , , , ) = IDragoRegistry(dragoRegistryAddress).fromId(poolId);

        if (poolAddress == address(0)) {
            return;
        }

        uint256 poolPrice = IPool(poolAddress).calcSharePrice();

        // allow smart contract calls only from pool itself
        if (_isContract(msg.sender)) {
            _assertContractIsPool(poolAddress);
        }

        // initialization is not necessary but explicit as to prevent failure in case of a future upgrade
        _initializeHwmIfUninitialized(poolId);

        (uint256 popReward, ) = _proofOfPerformanceInternal(poolId);

        // pop assets component is always positive, therefore we must update the hwm if positive performance
        _updateHwmIfPositivePerformance(poolPrice, poolId);

        IStaking(STAKING_PROXY_ADDRESS).creditPopReward(poolAddress, popReward);
    }

    /// @dev Allows RigoBlock Dao to update the pools registry.
    /// @param newDragoRegistryAddress Address of new registry.
    function setRegistry(address newDragoRegistryAddress)
        external
        override
        onlyRigoblockDao
    {
        dragoRegistryAddress = newDragoRegistryAddress;
    }

    /// @dev Allows RigoBlock Dao to update its address.
    /// @param newRigoblockDaoAddress Address of new dao.
    function setRigoblockDao(address newRigoblockDaoAddress)
        external
        override
        onlyRigoblockDao
    {
        rigoblockDaoAddress = newRigoblockDaoAddress;
    }

    /// @dev Allows rigoblock dao to update the authority.
    /// @param newAuthorityAddress Address of the authority.
    function setAuthority(address newAuthorityAddress)
        external
        override
        onlyRigoblockDao
    {
        authorityAddress = newAuthorityAddress;
    }

    /// @dev Allows RigoBlock Dao to set the parameters for a group.
    /// @param groupAddress Address of the pool's group.
    /// @param ratio Value of the ratio between assets and performance reward for a group.
    /// @param inflationFactor Value of the reward factor for a group.
    /// @notice onlyRigoblockDao can set ratio.
    function setGroupParams(
        address groupAddress,
        uint256 ratio,
        uint256 inflationFactor
    )
        external
        override
        onlyRigoblockDao
        isApprovedFactory(groupAddress)
    {
        // assert that group parameters are correct
        _assertValidGroupParams(ratio, inflationFactor);
        
        // update storage
        groupByAddress[groupAddress].rewardRatio = ratio;
        groupByAddress[groupAddress].epochReward = inflationFactor;
    }

    /*
     * CONSTANT PUBLIC FUNCTIONS
     */
    /// @dev Gets data of a pool.
    /// @param poolId Id of the pool.
    /// @return active Bool the pool is active.
    /// @return poolAddress address of the pool.
    /// @return poolGroup address of the pool factory.
    /// @return poolPrice price of the pool in wei.
    /// @return poolSupply total supply of the pool in units.
    /// @return poolValue total value of the pool in wei.
    /// @return epochReward value of the reward factor or said pool.
    /// @return ratio of assets/performance reward (from 0 to 10000).
    /// @return pop value of the pop reward to be claimed in GRGs.
    function getPoolData(uint256 poolId)
        external
        view
        override
        returns (
            bool active,
            address poolAddress,
            address poolGroup,
            uint256 poolPrice,
            uint256 poolSupply,
            uint256 poolValue,
            uint256 epochReward,
            uint256 ratio,
            uint256 pop
        )
    {
        active = _isActiveInternal(poolId);
        (poolAddress, poolGroup) = _addressFromIdInternal(poolId);
        (poolPrice, poolSupply, poolValue) = _getPoolPriceAndValueInternal(poolId);
        (epochReward, , ratio) = getRewardParameters(poolId);
        (pop, ) = _proofOfPerformanceInternal(poolId);
        return(
            active,
            poolAddress,
            poolGroup,
            poolPrice,
            poolSupply,
            poolValue,
            epochReward,
            ratio,
            pop
        );
    }

    /// @dev Returns the highwatermark of a pool.
    /// @param poolId Id of the pool.
    /// @return Value of the all-time-high pool nav.
    function getHwm(uint256 poolId)
        external
        view
        override
        returns (uint256)
    {
        return _getHwmInternal(poolId);
    }

    /// @dev Returns the split ratio of asset and performance reward.
    /// @param poolId Id of the pool.
    /// @return epochReward Value of the reward factor.
    /// @return epochTime Value of epoch time.
    /// @return ratio Value of the ratio from 1 to 100.
    function getRewardParameters(uint256 poolId)
        public
        view
        override
        returns (
            uint256 epochReward,
            uint256 epochTime,
            uint256 ratio
        )
    {
        ( , address groupAddress) = _addressFromIdInternal(poolId);
        epochReward = groupByAddress[groupAddress].epochReward;
        (epochTime, , , , ) = IStaking(STAKING_PROXY_ADDRESS).getParams();
        ratio = groupByAddress[groupAddress].rewardRatio;
    }

    /// @dev Returns the proof of performance reward for a pool.
    /// @param poolId Id of the pool.
    /// @return popReward Value of the pop reward in Rigo tokens.
    /// @return performanceReward Split of the performance reward in Rigo tokens.
    /// @notice epoch reward should be big enough that it.
    /// @notice can be decreased if number of funds increases.
    /// @notice should be at least 10^6 (just as pool base) to start with.
    /// @notice rigo token has 10^18 decimals.
    function proofOfPerformance(uint256 poolId)
        external
        view
        override
        returns (
            uint256 popReward,
            uint256 performanceReward
        )
    {
        return _proofOfPerformanceInternal(poolId);
    }

    /// @dev Checks whether a pool is registered and active.
    /// @param poolId Id of the pool.
    /// @return Bool the pool is active.
    function isActive(uint256 poolId)
        external
        view
        override
        returns (bool)
    {
        return _isActiveInternal(poolId);
    }

    /// @dev Returns the address and the group of a pool from its id.
    /// @param poolId Id of the pool.
    /// @return pool Address of the target pool.
    /// @return group Address of the pool's group.
    function addressFromId(uint256 poolId)
        external
        view
        override
        returns (
            address pool,
            address group
        )
    {
        return _addressFromIdInternal(poolId);
    }

    /// @dev Returns the price a pool from its id.
    /// @param poolId Id of the pool.
    /// @return poolPrice Price of the pool in wei.
    /// @return totalTokens Number of tokens of a pool (totalSupply).
    function getPoolPrice(uint256 poolId)
        external
        view
        override
        returns (
            uint256 poolPrice,
            uint256 totalTokens
        )
    {
        (poolPrice, totalTokens, ) = _getPoolPriceAndValueInternal(poolId);
    }

    /// @dev Returns the value of a pool from its id.
    /// @param poolId Id of the pool.
    /// @return aum Total value of the pool in ETH.
    function calcPoolValue(uint256 poolId)
        external
        view
        override
        returns (uint256 aum)
    {
        ( , , aum) = _getPoolPriceAndValueInternal(poolId);
    }

    /*
     * INTERNAL FUNCTIONS
     */
    /// @dev Initializes the High Watermark if unitialized.
    /// @param poolId Number of the pool Id in registry.
    function _initializeHwmIfUninitialized(uint256 poolId)
        internal
    {
        if (_highWaterMark[poolId] == uint256(0)) {
            _highWaterMark[poolId] = 1 ether;
        }
    }

    /// @dev Updates high-water mark if positive performance.
    /// @param poolPrice Value of the pool price.
    /// @param poolId Number of the pool Id in registry.
    function _updateHwmIfPositivePerformance(
        uint256 poolPrice,
        uint256 poolId
    )
        internal
    {
        if (poolPrice > _highWaterMark[poolId]) {
            _highWaterMark[poolId] = poolPrice;
        }
    }

    /// @dev Returns the proof of performance reward for a pool.
    /// @param poolId Id of the pool.
    /// @return popReward Value of the pop reward in Rigo tokens.
    /// @return performanceReward Split of the performance reward in Rigo tokens.
    /// @notice epoch reward should be big enough that it  can be decreased when number of funds increases
    /// @notice should be at least 10^6 (just as pool base) to start with.
    function _proofOfPerformanceInternal(uint256 poolId)
        internal
        view
        returns (
            uint256 popReward,
            uint256 performanceReward
        )
    {
        (uint256 newPrice, uint256 tokenSupply, uint256 poolValue) = _getPoolPriceAndValueInternal(poolId);
        (address poolAddress, ) = _addressFromIdInternal(poolId);
        (uint256 epochReward, uint256 epochTime, uint256 rewardRatio) = getRewardParameters(poolId);

        uint256 assetsComponent = safeMul(
            poolValue,
            epochReward
        ) * epochTime / 1 days; // proportional to epoch time

        uint256 performanceComponent = newPrice <= _getHwmInternal(poolId) ? uint256(0) : safeMul(
            safeMul(
                (newPrice - _getHwmInternal(poolId)),
                tokenSupply
            ) / POOL_BASE,
            epochReward
        ) * 365; // 365 = 365 days / 1 days

        // reward is inversely proportional to Eth in pool
        uint256 ethBalanceAdjustment = _ethBalanceAdjustmentInternal(poolAddress, poolValue);
        uint256 assetsReward = (
            safeMul(
                assetsComponent,
                safeSub(10000, rewardRatio) // 10000 = 100%
            ) / 10000 ether
        ) * ethBalanceAdjustment / 1 ether;

        performanceReward = safeDiv(
            safeMul(performanceComponent, rewardRatio),
            10000 ether
        ) * ethBalanceAdjustment / 1 ether;

        popReward = safeAdd(performanceReward, assetsReward);
    }

    /// @dev Returns the high-watermark of the pool.
    /// @param poolId Number of the pool in registry.
    /// @return Number high-watermark.
    function _getHwmInternal(uint256 poolId)
        internal
        view
        returns (uint256)
    {
        if (_highWaterMark[poolId] == uint256(0)) {
            return (1 ether);

        } else {
            return _highWaterMark[poolId];
        }
    }

    /// @dev Returns the non-linear rewards adjustment by eth.
    /// @param poolAddress Address of the pool.
    /// @param poolValue Number of value of the pool in wei.
    /// @return Number non-linear adjustment.
    function _ethBalanceAdjustmentInternal(
        address poolAddress,
        uint256 poolValue
    )
        internal
        view
        returns (uint256)
    {
        uint256 poolEthBalance = address(IPool(poolAddress)).balance;
        
        _assertPoolEthBalanceAndValueValid(poolEthBalance, poolValue);

        // logistic function progression g(x)=e^x/(1+e^x).
        // rebased on {(poolEthBalance / poolValue)} b [0.025:0.6], x b [-1.9:2.8].
        if (1000 * poolEthBalance >= 800 * poolValue) {
            return (1 ether);

        } else if (1000 * poolEthBalance >= 600 * poolValue) {
            return (1 ether * 943 / 1000);

        } else if (1000 * poolEthBalance >= 500 * poolValue) {
            return (1 ether * 881 / 1000);

        } else if (1000 * poolEthBalance >= 400 * poolValue) {
            return (1 ether * 769 / 1000);

        } else if (1000 * poolEthBalance >= 300 * poolValue) {
            return (1 ether * 599 / 1000);

        } else if (1000 * poolEthBalance >= 200 * poolValue) {
            return (1 ether * 401 / 1000);

        } else if (1000 * poolEthBalance >= 100 * poolValue) {
            return (1 ether * 231 / 1000);

        } else if (1000 * poolEthBalance >= 75 * poolValue) {
            return (1 ether * 198 / 1000);

        } else if (1000 * poolEthBalance >= 50 * poolValue) {
            return (1 ether * 168 / 1000);

        } else if (1000 * poolEthBalance >= 38 * poolValue) {
            return (1 ether * 155 / 1000);

        } else if (1000 * poolEthBalance >= 25 * poolValue) {
            return (1 ether * 142 / 1000);

        } else { // reward is 0 for any pool not backed by at least 2.5% eth
            revert("ETH_BELOW_2.5_PERCENT_AUM_ERROR");
        }
    }

    /// @dev Checks whether a pool is registered and active.
    /// @param poolId Id of the pool.
    /// @return Bool the pool is active.
    function _isActiveInternal(uint256 poolId)
        internal view
        returns (bool)
    {
        (address poolAddress, , , , , ) = IDragoRegistry(dragoRegistryAddress).fromId(poolId);
        if (poolAddress != address(0)) {
            return true;
        } else return false;
    }

    /// @dev Returns the address and the group of a pool from its id.
    /// @param poolId Id of the pool.
    /// @return pool Address of the target pool.
    /// @return group Address of the pool's group.
    function _addressFromIdInternal(uint256 poolId)
        internal
        view
        returns (
            address pool,
            address group
        )
    {
        (pool, , , , , group) = IDragoRegistry(dragoRegistryAddress).fromId(poolId);
        return (pool, group);
    }

    /// @dev Returns price, supply, aum of a pool from its id.
    /// @param poolId Id of the pool.
    /// @return poolPrice Price of the pool in wei.
    /// @return totalTokens Number of tokens of a pool (totalSupply).
    /// @return aum Address of the target pool.
    function _getPoolPriceAndValueInternal(uint256 poolId)
        internal
        view
        returns (
            uint256 poolPrice,
            uint256 totalTokens,
            uint256 aum
        )
    {
        (address poolAddress, ) = _addressFromIdInternal(poolId);
        IPool pool = IPool(poolAddress);
        poolPrice = pool.calcSharePrice();
        totalTokens = pool.totalSupply();

        // revert if pool has no tokens issues or price is 0
        if (poolPrice == uint256(0) || totalTokens == uint256(0)) {
            revert("POOL_PRICE_OR_TOTAL_SUPPLY_NULL_ERROR");
        }

        aum = safeMul(poolPrice, totalTokens) / POOL_BASE;
    }

    /// @dev Asserts that the caller is the RigoBlock Dao.
    function _assertCallerIsRigoblockDao()
        internal
        view
    {
        if (msg.sender != rigoblockDaoAddress) {
            revert("CALLER_NOT_RIGOBLOCK_DAO_ERROR");
        }
    }

    /// @dev Determines whether an address is an account or a contract
    /// @param target Address to be inspected
    /// @return Boolean the address is a contract
    function _isContract(address target)
        internal
        view
        returns (bool)
    {
        uint size;
        // solhint-disable-next-line
        assembly {
            size := extcodesize(target)
        }
        return size > 0;
    }

    /// @dev Asserts whether the caller contract is the pool
    /// @param poolAddress Address of the calling pool
    function _assertContractIsPool(address poolAddress)
        internal
        view
    {
        if (msg.sender != poolAddress) {
            revert("SMART_CONTRACT_CALLER_IS_NOT_POOL_ERROR");
        }
    }

    /// @dev Asserts that an address is an approved factory.
    /// @param _factory Address of the target factory.
    function _assertIsApprovedFactory(address _factory)
        internal
        view
    {
        if (!AuthorityFace(authorityAddress).isWhitelistedFactory(_factory)) {
            revert("NOT_APPROVED_AUTHORITY_ERROR");
        }
    }

    /// @dev Asserts that the group parameters are valid.
    /// @param ratio Value of the ratio between assets and performance reward for a group.
    /// @param inflationFactor Value of the reward factor for a group.
    function _assertValidGroupParams(
        uint256 ratio,
        uint256 inflationFactor
    )
        internal
        pure
    {
        // ratio is from 0 to 10000, 10000 = 100%
        if (ratio > 10000) {
            revert("TOO_BIG_RATIO_ERROR");
        }
        
        // inflationFactor is between 1e12 and 1e21
        if (inflationFactor < 1e12 || inflationFactor > 1e21) {
            revert("INVALID_INFLATION_FACTOR_ERROR");
        }
    }
    
    /// @dev Asserts than pool ETH balance and total value are ordinary and not dust.
    /// @param poolEthBalance Value of the ETH balance.
    /// @param poolValue Total Value of the pool.
    function _assertPoolEthBalanceAndValueValid(
        uint256 poolEthBalance,
        uint256 poolValue
    )
        internal
        pure
    {
        // assert ETH in pool is below pool value
        if (poolEthBalance > poolValue) {
            revert("ETH_ABOVE_AUM_ERROR");
        }
        
        // prevent dust from small pools
        if (poolEthBalance < 1e15 || poolValue < 1e16) {
            revert("POOL_OR_BALANCE_DUST_ERROR");
        }
    }
}