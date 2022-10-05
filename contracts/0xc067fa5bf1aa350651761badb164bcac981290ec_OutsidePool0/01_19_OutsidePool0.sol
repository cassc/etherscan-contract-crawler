// SPDX-License-Identifier: Apache-2.0

// Changes:
// 1. Separated the bond token address from the pool token address so that the pool can hold bHome and reward Bacon.
//    Though I suppose this makes it not a very good bond...

pragma solidity ^0.8.4;

import "./../@openzeppelin/contracts/token/ERC20/IERC20.sol";
import './../@openzeppelin/contracts/utils/math/SafeMath.sol';
import "./../@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import './../@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import './../@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import "./../PoolStakingRewards/PoolStakingRewards6.sol";
import "./../Staking/Staking4.sol";


import "hardhat/console.sol";


contract OutsidePool0 is Initializable, PausableUpgradeable, ReentrancyGuardUpgradeable {

    // lib
    using SafeMath for uint256;
    using SafeMath for uint128;
    using SafeMath for uint64;
    using SafeMath for uint16;


    // contracts
    PoolStakingRewards6 private poolStakingRewards;
    address private staking;
    mapping(address => uint) approvedPools;
    address guardianAddress;


    mapping(address => uint[]) private epochs;
    mapping(address => uint128) public lastInitializedEpoch;
    mapping(address => uint128) private lastEpochIdHarvested;
    uint private numberOfEpochs;

    // events
    event MassHarvest(address indexed user, uint256 epochsHarvested, uint256 totalValue);
    event Harvest(address indexed user, uint128 indexed epochId, uint256 amount);


    function initialize(address _guardianAddress, address _poolStakingRewards, address _staking, uint _numberOfEpochs) public initializer {
        guardianAddress = _guardianAddress;
        poolStakingRewards = PoolStakingRewards6(_poolStakingRewards);
        staking = _staking;
        numberOfEpochs = _numberOfEpochs;
    }

    function approvePool(address poolAddress, uint amountPerEpoch) public {
        require(msg.sender == guardianAddress, "OutsidePool: unapproved sender");
        approvedPools[poolAddress] = amountPerEpoch;
        epochs[poolAddress] = new uint[](numberOfEpochs + 1);

        address[] memory tokens = new address[](1);
        tokens[0] = poolAddress;
        uint128 currentEpoch = Staking4(staking).getCurrentEpoch();

        Staking4(staking).manualBatchEpochInit(tokens, 0, currentEpoch);
        for (uint128 i = 1; i < currentEpoch; i++) {
          _initEpoch(poolAddress, i);
        }
    }

    function revokePool(address poolAddress) public {
        require(msg.sender == guardianAddress, "OutsidePool: unapproved sender");
        approvedPools[poolAddress] = 0;
    }

    function stake(address pool, uint256 amount) public whenNotPaused nonReentrant returns (bool) {
        require(approvedPools[pool] > 0, "OutsidePool: must be approved sender");
        IERC20 token = IERC20(pool);
        token.transferFrom(msg.sender, staking, amount);

        Staking4(staking).deposit(pool, msg.sender, amount);
        return true;
    }

    function unstake(address pool, uint256 amount) public whenNotPaused nonReentrant {
        require(approvedPools[pool] > 0, "OutsidePool: must be approved sender");
        Staking4(staking).withdraw(pool, msg.sender, amount);
    }

    function massHarvest(address pool, address wallet) external whenNotPaused nonReentrant returns (uint){
        require(approvedPools[pool] > 0, "OutsidePool: must be approved sender");
        uint totalDistributedValue = 0;

        //added so it doesn't fail on first epoch
        uint epochId = getCurrentEpoch();
        if(epochId == 0){
            return 0;
        }
        
        epochId = epochId.sub(1); // fails in epoch 0
        // force max number of epochs
        if (epochId > numberOfEpochs) {
            epochId = numberOfEpochs;
        }

        for (uint128 i = lastEpochIdHarvested[wallet] + 1; i <= epochId; i++) {
            // i = epochId
            // compute distributed Value and do one single transfer at the end
            uint harvested = _harvest(pool, wallet, i);
            totalDistributedValue += harvested;
        }

        emit MassHarvest(wallet, epochId - lastEpochIdHarvested[wallet], totalDistributedValue);

        if (totalDistributedValue > 0) {
            poolStakingRewards.subMint(wallet, totalDistributedValue);
        }

        return totalDistributedValue;
    }

    function harvest (address pool, address wallet, uint128 epochId) external whenNotPaused nonReentrant returns (uint){
        // Defer to PoolStakingRewards
        require(approvedPools[pool] > 0, "OutsidePool: must be approved sender");
        // checks for requested epoch
        require (getCurrentEpoch() > epochId, "OutsidePool: This epoch is in the future");
        require(epochId <= numberOfEpochs, "OutsidePool: Maximum number of epochs is 2000");
        require (lastEpochIdHarvested[wallet].add(1) == epochId, "OutsidePool: Harvest in order");
        uint userReward = _harvest(pool, wallet, epochId);
        if (userReward > 0) {
             poolStakingRewards.subMint(wallet, userReward);
        }
        emit Harvest(wallet, epochId, userReward);
        return userReward;
    }

    // views
    function getTotalEpochs() external view returns (uint) {
        return numberOfEpochs;
    }

    // calls to the staking smart contract to retrieve the epoch total pool size
    function getPoolSize(address pool, uint128 epochId) public view returns (uint) {
        return Staking4(staking).getEpochPoolSize(pool, epochId);
    }

    function getCurrentEpoch() public view returns (uint128) {
        return Staking4(staking).getCurrentEpoch();
    }

    // calls to the staking smart contract to retrieve user balance for an epoch
    function getEpochStake(address pool, address userAddress, uint128 epochId) public view returns (uint) {
        return Staking4(staking).getEpochUserBalance(userAddress, pool, epochId);
    }

    function getCurrentEpochStake(address pool, address userAddress) public view returns (uint) {
        return Staking4(staking).getEpochUserBalance(userAddress, pool, getCurrentEpoch());
    }

    function getCurrentBalance(address userAddress, address pool) external view returns (uint) {
        return Staking4(staking).balanceOf(userAddress, pool);
    }

    function userLastEpochIdHarvested() external view returns (uint){
        return lastEpochIdHarvested[msg.sender];
    }

    // internal methods
    function _initEpoch(address pool, uint128 epochId) internal {
        require(lastInitializedEpoch[pool].add(1) == epochId, "OutsidePool: Epoch can be init only in order");
        lastInitializedEpoch[pool] = epochId;
        // call the staking smart contract to init the epoch
        epochs[pool][epochId] = getPoolSize(pool, epochId);
    }

    function _harvest(address pool, address wallet, uint128 epochId) internal returns (uint) {
        // try to initialize an epoch. if it can't it fails
        // if it fails either user either a BarnBridge account will init not init epochs
        if (lastInitializedEpoch[pool] < epochId) {
            _initEpoch(pool, epochId);
        }
        lastEpochIdHarvested[wallet] = epochId;

        // exit if there is no stake on the epoch
        uint epoch = epochs[pool][epochId];
        if (epoch == 0) {
            return 0;
        }

        return approvedPools[pool]
        .mul(getEpochStake(pool, wallet, epochId))
        .div(epoch);
    }

    function pause() public {
        require(msg.sender == guardianAddress, "caller must be guardian");
        _pause();
    }

    function unpause() public {
        require(msg.sender == guardianAddress, "caller must be guardian");
        _unpause();
    }
}