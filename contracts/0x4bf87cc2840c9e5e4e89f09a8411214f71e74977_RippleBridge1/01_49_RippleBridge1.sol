// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import "./../@openzeppelin/contracts/token/ERC20/IERC20.sol";
import './../@openzeppelin/contracts/utils/math/SafeMath.sol';
import "./../@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import './../@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import './../@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import './../@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

import './../HomeBoost/HomeBoost4.sol';
import './../PoolCore/Pool16.sol';


contract RippleBridge1 is Initializable, PausableUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeMath for uint128;
    using SafeMath for uint64;
    using SafeMath for uint16;

    event DepositHome(string indexed indexed_xrp_address, string xrp_address, uint256 amount);
    event DepositBoost(string indexed indexed_xrp_address, string xrp_address, uint256 boostId);
    event WithdrawHome(bytes32 indexed xrp_transaction_id, uint256 amount);
    event WithdrawBoost(bytes32 indexed xrp_transaction_id, uint256 boostId);
    event ClaimBoostRewards(uint256 indexed boostId, uint256 amount);

    address poolAddr;
    address boostAddr;

    function initialize(address owner, address _poolAddr, address _boostAddr) public initializer {
        __Ownable_init();
        super.transferOwnership(owner);
        poolAddr = _poolAddr;
        boostAddr = _boostAddr;
    }

    // Transfer HOME or a Boost into the contract.
    // Raise an Event to let the bridge know to mint amount to the xrp_address
    function depositHome(string calldata xrp_address, uint256 amount) public nonReentrant {
        Pool16 pool = Pool16(poolAddr);
        pool.transferFrom(msg.sender, address(this), amount);
        emit DepositHome(xrp_address, xrp_address, amount);
    }

    function depositBoost(string calldata xrp_address, uint256 boostId) public nonReentrant {
        HomeBoost4 booster = HomeBoost4(boostAddr);

        // Only one year boosts with auto-renew on can be deposited
        HomeBoost4.Boost memory token = booster.getRawTokenData(boostId);
        require(token.level == 2, "Boost not one year type");
        require(token.endIteration == 0, "Boost isn't auto renewing");

        booster.transferFrom(msg.sender, address(this), boostId);

        emit DepositBoost(xrp_address, xrp_address, boostId);
    }

    // Pass through functions for handling Boost rewards.
    // Raise an event for the bridge to mint and send HOME to holders.
    function claimBoostRewards(uint256 boostId) public nonReentrant returns (uint256) {
        HomeBoost4  booster = HomeBoost4(boostAddr);
        uint256 rewards = booster.claimRewards(boostId);

        emit ClaimBoostRewards(boostId, rewards);
        return rewards;
    }

    // Withdraw HOME from the contract. Must reference a related xrp_transaction.
    // Send the HOME or a Boost to the eth_address.
    // These can only be called by the contract owner
    function withdrawHome(address recipient, uint256 amount, bytes32 xrp_transaction_id) public onlyOwner {
        Pool16 pool = Pool16(poolAddr);
        pool.transfer(recipient, amount);
        emit WithdrawHome(xrp_transaction_id, amount);
    }
    
    function withdrawBoost(address recipient, uint256 boostId, bytes32 xrp_transaction_id) public onlyOwner {
        HomeBoost4 booster = HomeBoost4(boostAddr);
        booster.transferFrom(address(this), recipient, boostId);
        emit WithdrawBoost(xrp_transaction_id, boostId);        
    }
}