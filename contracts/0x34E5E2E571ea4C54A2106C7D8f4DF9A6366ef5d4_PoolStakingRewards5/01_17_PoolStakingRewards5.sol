// SPDX-License-Identifier: Apache-2.0

// Changes:
// 1. Separated the bond token address from the pool token address so that the pool can hold bHome and reward Bacon.
//    Though I suppose this makes it not a very good bond...

pragma solidity ^0.8.4;

import './../@openzeppelin/contracts/utils/math/SafeMath.sol';
import "./../@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./../Staking/IStaking.sol";
import "./../Staking/Staking4.sol";
import "./../@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./../BaconCoin/BaconCoin3.sol";


contract PoolStakingRewards5 is Initializable {

    // lib
    using SafeMath for uint;
    using SafeMath for uint128;

    // Per epoch rewards
    uint256 constant GUARDIAN_REWARD = 2_358_720e18;
    uint256 constant DAO_REWARD = 1_088_640e18;

    // constants
    // end of year one rewards was block 15651074
    // airdrop_ends_block_number (from airdrop script) was: 14127375
    // year one reward per block: 100 Bacon
    // total remaining rewards for year 1 = 100 * (endOfYearOneBlock - rewardsAirdropBlock)
    // = 100 * (15651074-14127375)
    // uint public constant TOTAL_DISTRIBUTED_AMOUNT = 152369900;
    // There are roughly 19 weeks left in our 1 year rewards term
    // starting the 19th of May 2022
    // uint public constant NR_OF_EPOCHS = 19;
    // uint128 public constant EPOCHS_DELAYED_FROM_STAKING_CONTRACT = 0;

    // state variables

    // addresses
    address private _poolTokenAddress;
    // contracts
    BaconCoin3 private _bacon;
    IStaking private _staking;
    // TODO: maybe private?
    mapping(address => bool) isApprovedPool;
    address guardianAddress;
    address daoAddress;


    uint[] private epochs;
    uint private _totalAmountPerEpoch;
    uint128 public lastInitializedEpoch;
    mapping(address => uint128) private lastEpochIdHarvested;
    uint public epochDuration; // init from staking contract
    uint public epochStart; // init from staking contract
    uint private _numberOfEpochs;

    /* PoolStakingRewards1 Variables */
    address airdropContract;

    // events
    event MassHarvest(address indexed user, uint256 epochsHarvested, uint256 totalValue);
    event Harvest(address indexed user, uint128 indexed epochId, uint256 amount);

    function setGuardianAddress(address _guardianAddress) public {
        require(msg.sender == guardianAddress, "PoolStakingRewards: unapproved sender");
        lastEpochIdHarvested[_guardianAddress] =  lastEpochIdHarvested[guardianAddress];
        guardianAddress = _guardianAddress;
    }

    // To be called after baconCoin0 is deployed
    function setDAOAddress(address _DAOAddress) public {
        require(msg.sender == guardianAddress, "PoolStakingRewards: unapproved sender");
        lastEpochIdHarvested[_DAOAddress] =  lastEpochIdHarvested[daoAddress];
        daoAddress = _DAOAddress;
    }

    function setPerEpoch(uint newPerEpoch) public {
        require(msg.sender == guardianAddress, "unapproved sender");
        _totalAmountPerEpoch = newPerEpoch;
    }

    function transferMintRights(address newMinter) public {
        require(msg.sender == guardianAddress, "PoolStakingRewards: unapproved sender");
        _bacon.setStakingContract(newMinter);
    }

    function approvePool(address poolAddress) public {
        require(msg.sender == guardianAddress, "PoolStakingRewards: unapproved sender");
        isApprovedPool[poolAddress] = true;
    }

    function revokePool(address poolAddress) public {
        require(msg.sender == guardianAddress, "PoolStakingRewards: unapproved sender");
        isApprovedPool[poolAddress] = false;
    }

    function stake(address wallet, uint256 amount) public returns (bool) {
        require(isApprovedPool[msg.sender], "PoolStakingRewards: must be approved sender");
        // expects that the users Home has already been transferred to the staking contract
        _staking.deposit(_poolTokenAddress, wallet, amount);

        return true;
    }

    // PoolStakingRewards no longer allowed from any address. This is now done by claiming a HomeBoost.
    function unstake(uint256 amount) public {
        require(false, "not allowed");
    }

    function unstakeForWallet(address wallet, uint256 amount) public {
        require(isApprovedPool[msg.sender], "PoolStakingRewards: must be approved sender");
        _unstakeInternal(wallet, amount);
    }

    function transferStake(uint256 amount, address from, address to) public {
        require(isApprovedPool[msg.sender], "PoolStakingRewards: must be approved sender");
        Staking4(address(_staking)).transfer(_poolTokenAddress, amount, from, to);
    }

    // public methods
    // public method to harvest all the unharvested epochs until current epoch - 1
    function massHarvest(address wallet) external returns (uint){
        require(isApprovedPool[msg.sender], "PoolStakingRewards: must be approved sender");
        uint totalDistributedValue = 0;

        //added so it doesn't fail on first epoch
        if(_getEpochId() == 0){
            return 0;
        }
        
        uint epochId = _getEpochId().sub(1); // fails in epoch 0
        // force max number of epochs
        if (epochId > _numberOfEpochs) {
            epochId = _numberOfEpochs;
        }

        for (uint128 i = lastEpochIdHarvested[wallet] + 1; i <= epochId; i++) {
            // i = epochId
            // compute distributed Value and do one single transfer at the end
            totalDistributedValue += _harvest(wallet, i);
        }

        emit MassHarvest(wallet, epochId - lastEpochIdHarvested[wallet], totalDistributedValue);

        if (totalDistributedValue > 0) {
            _bacon.mint(wallet, totalDistributedValue);
        }

        return totalDistributedValue;
    }

    function harvest (address wallet, uint128 epochId) external returns (uint){
        require(isApprovedPool[msg.sender], "PoolStakingRewards: must be approved sender");
        // checks for requested epoch
        require (_getEpochId() > epochId, "PoolStakingRewards: This epoch is in the future");
        require(epochId <= _numberOfEpochs, "PoolStakingRewards: Maximum number of epochs is 12");
        require (lastEpochIdHarvested[wallet].add(1) == epochId, "PoolStakingRewards: Harvest in order");
        uint userReward = _harvest(wallet, epochId);
        if (userReward > 0) {
             _bacon.mint(wallet, userReward);
        }
        emit Harvest(wallet, epochId, userReward);
        return userReward;
    }

    // views
    function getTotalEpochs() external view returns (uint) {
        return _numberOfEpochs;
    }

    function getRewardPerEpoch() external view returns (uint) {
        return _totalAmountPerEpoch;
    }

    // calls to the staking smart contract to retrieve the epoch total pool size
    function getPoolSize(uint128 epochId) external view returns (uint) {
        return _getPoolSize(epochId);
    }

    function getCurrentEpoch() external view returns (uint) {
        return _getEpochId();
    }

    // calls to the staking smart contract to retrieve user balance for an epoch
    function getEpochStake(address userAddress, uint128 epochId) external view returns (uint) {
        return _getUserBalancePerEpoch(userAddress, epochId);
    }

    function getCurrentEpochStake(address userAddress) external view returns (uint) {
        return _getUserBalancePerEpoch(userAddress, _getEpochId());
    }

    function getCurrentBalance(address userAddress) external view returns (uint) {
        return _staking.balanceOf(userAddress, _poolTokenAddress);
    }

    function userLastEpochIdHarvested() external view returns (uint){
        return lastEpochIdHarvested[msg.sender];
    }

    // internal methods

    function _unstakeInternal(address wallet, uint256 amount) internal {
        _staking.withdraw(_poolTokenAddress, wallet, amount);
    }

    function _initEpoch(uint128 epochId) internal {
        require(lastInitializedEpoch.add(1) == epochId, "PoolStakingRewards: Epoch can be init only in order");
        lastInitializedEpoch = epochId;
        // call the staking smart contract to init the epoch
        epochs[epochId] = _getPoolSize(epochId);
    }

    function _harvest (address wallet, uint128 epochId) internal returns (uint) {
        // try to initialize an epoch. if it can't it fails
        // if it fails either user either a BarnBridge account will init not init epochs
        if (lastInitializedEpoch < epochId) {
            _initEpoch(epochId);
        }
        // Set user state for last harvested
        lastEpochIdHarvested[wallet] = epochId;
        // compute and return user total reward. For optimization reasons the transfer have been moved to an upper layer (i.e. massHarvest needs to do a single transfer)
        if(wallet == daoAddress){
            return DAO_REWARD;
        }
        if(wallet == guardianAddress){
            return GUARDIAN_REWARD;
        }

        // exit if there is no stake on the epoch
        if (epochs[epochId] == 0) {
            return 0;
        }
        return _totalAmountPerEpoch
        .mul(_getUserBalancePerEpoch(wallet, epochId))
        .div(epochs[epochId]);
    }

    // retrieve _poolTokenAddress token balance
    function _getPoolSize(uint128 epochId) internal view returns (uint) {
        return _staking.getEpochPoolSize(_poolTokenAddress, _stakingEpochId(epochId));
    }

    // retrieve _poolTokenAddress token balance per user per epoch
    function _getUserBalancePerEpoch(address userAddress, uint128 epochId) internal view returns (uint){
        return _staking.getEpochUserBalance(userAddress, _poolTokenAddress, _stakingEpochId(epochId));
    }

    // compute epoch id from block.timestamp and epochStart date
    function _getEpochId() internal view returns (uint128 epochId) {
        if (block.timestamp < epochStart) {
            return 0;
        }
        epochId = uint128(block.timestamp.sub(epochStart).div(epochDuration).add(1));
    }

    // get the staking epoch
    function _stakingEpochId(uint128 epochId) pure internal returns (uint128) {
        return epochId;
    }

    function mintBacon(address wallet, uint256 userReward) public {
        require(msg.sender == airdropContract, "PoolStakingRewards: unapproved sender");
        _bacon.mint(wallet, userReward);
    }

    function getAndClearReward(address wallet) external returns (uint256) {
        require(isApprovedPool[msg.sender], "PoolStakingRewards: must be approved sender");

        return _staking.getAndClearReward(wallet, _poolTokenAddress);
    }

}