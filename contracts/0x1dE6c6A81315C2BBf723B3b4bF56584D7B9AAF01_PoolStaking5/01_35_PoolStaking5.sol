// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./../@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./../@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import './../BaconCoin/BaconCoin3.sol';
import './../PoolStakingRewards/PoolStakingRewards0.sol';
import './../PoolCore/Pool10.sol';


import './../@openzeppelin/contracts/utils/math/SafeMath.sol';
import './../@openzeppelin/contracts/utils/math/SignedSafeMath.sol';

contract PoolStaking5 is Initializable {
    using SignedSafeMath for int256;
    using SafeMath for uint256;

    uint256 constant PER_BLOCK_DECAY_18_DECIMALS = 999999775700000000;
    uint256 constant PER_BLOCK_DECAY_INVERSE = 1000000224300050310;
    uint256 constant DENOM = 224337829e21;
    uint256 constant GUARDIAN_REWARD = 39e18;
    uint256 constant DAO_REWARD = 18e18;
    uint256 constant COMMUNITY_REWARD = 50e18;
    uint256 constant COMMUNITY_REWARD_BONUS = 100e18;

    uint256 stakeAfterBlock;
    address guardianAddress;
    address daoAddress;
    address baconCoinAddress;
    address[] poolAddresses;

    uint256[] updateEventBlockNumber;
    uint256[] updateEventNewAmountStaked;
    uint256 updateEventCount;
    uint256 currentStakedAmount;

    mapping(address => uint256) public userStaked;
    mapping(address => uint256) public userLastDistribution;

    uint256 oneYearBlock;

    struct UnstakeRecord {
        uint256 endBlock;
        uint256 amount;
    }

    // PoolStaking2 storage
    uint256 unstakingLockupBlockDelta;
    mapping(address => UnstakeRecord) userToUnstake;
    uint256 pendingWithdrawalAmount;

    //PoolStaking3 storage for nonReentrant modifier
    //modifier and variables could not be imported via inheratance given upgradability rules
    mapping(address => bool) isApprovedPool;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    //PoolStaking4 storage
    address newStakingContract;

    // All interesting functions removed to reduce surface area.

    /**  
    *   @dev Function version returns uint depending on what version the contract is on
    */
    function version() public pure returns (uint) {
        return 5;
    }

    function getContractInfo() public view returns (uint256, uint256, address, address, address, address  [] memory, uint256, uint256, uint256) {
        return (
            stakeAfterBlock,
            oneYearBlock,
            guardianAddress,
            daoAddress,
            baconCoinAddress,
            poolAddresses,
            updateEventCount,
            currentStakedAmount,
            pendingWithdrawalAmount
        );
    }

    function getPendingWithdrawInfo(address _holderAddress) public view returns(uint256, uint256, uint256) {
        return (
            userToUnstake[_holderAddress].endBlock,
            userToUnstake[_holderAddress].amount,
            pendingWithdrawalAmount
        );
    }

    function getUserLastDistributed(address wallet) public view returns (uint256) {
        return (userLastDistribution[wallet]);
    }
}