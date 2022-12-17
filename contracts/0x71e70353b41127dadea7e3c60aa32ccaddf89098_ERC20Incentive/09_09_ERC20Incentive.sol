// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

/// @title Incentive system for ERC20 claimable token
contract ERC20Incentive is Initializable, OwnableUpgradeable, PausableUpgradeable {
    struct Incentive {
        address creator;
        uint256 lastClaimDate;
        uint256 lastUpdateDate;
        uint256 availableIncentives;
        uint256 claimedIncentives;
        uint256 totalIncentives;
    }

    // ==========STATE VARIABLES============
    uint256 public maxPerBatch;
    IERC20Upgradeable public token;
    // token balance
    uint256 public reserveBalance;
    // beneficiary to incentive
    mapping(address => Incentive) public incentives;

    // ==========EVENTS============
    event IncentivePersisted(address beneficiary, uint256 amount);
    event IncentiveClaimed(address indexed beneficiary, uint256 amount);
    event TopUp(address indexed from, uint256 amount);

    // ==========ERRORS============
    error ClaimFailed();
    error TopUpFailed();
    error IncentiveTooLow();
    error InsufficientReserveBalance();
    error NotOwnedIncentive();

    /// Upgradeable contracts initializer
    /// @param _token IERC20Upgradeable token to be used as incentive
    /// @dev sets the token instance to be used in this contract.
    function initialize(IERC20Upgradeable _token) public initializer {
        __Ownable_init();
        token = _token;
        maxPerBatch = 10000;
    }

    /// helper function for transfering from sender to contract
    /// @param _amount to transfer from sender
    /// @dev uses the ERC20 transferFrom for token transfer,
    ///      allowance must be given to the contract ahead of time.
    function topUp(uint256 _amount) external returns (bool status) {
        status = token.transferFrom(msg.sender, address(this), _amount);
        if (!status) {
            revert TopUpFailed();
        }
        reserveBalance += _amount;
        emit TopUp(msg.sender, _amount);
    }

    /// @dev top-up incentive for claiming
    /// @param _beneficiary to add incentive to, create if not exist
    /// @param _amount to add to the incentive
    function addAmountToIncentive(address _beneficiary, uint256 _amount) public onlyOwner {
        if (_amount > reserveBalance) {
            revert InsufficientReserveBalance();
        }

        Incentive storage _i = incentives[_beneficiary];
        if (_i.totalIncentives == 0) {
            _i.creator = msg.sender;
        }
        if (!(_i.creator == msg.sender)) {
            revert NotOwnedIncentive();
        }
        reserveBalance -= _amount;

        _i.totalIncentives += _amount;
        _i.availableIncentives += _amount;
        _i.lastUpdateDate = block.timestamp;
        emit IncentivePersisted(_beneficiary, _i.availableIncentives);
    }

    /// @dev top-up incentive for claiming
    /// @param _beneficiaries to add incentive to, create if not exist
    /// @param _amounts to add to the incentive, map to beneficiary of the same index
    function batchAddAmountToIncentive(address[] memory _beneficiaries, uint256[] memory _amounts) external onlyOwner {
        require(_beneficiaries.length <= maxPerBatch, "batch too much");
        require(_beneficiaries.length == _amounts.length, "Unequal beneficiaries and amounts counts");
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            addAmountToIncentive(_beneficiaries[i], _amounts[i]);
        }
    }

    /// Allows beneficiary to claim an incentive
    /// @return status Boolean value for transaction activity
    /// @dev transfers specified amount to valid incentive beneficiary. Incentive is persisted to reflect claim.
    function claim() external whenNotPaused returns (bool status) {
        address _beneficiary = msg.sender;
        Incentive storage _i = incentives[_beneficiary];
        uint256 _amount = _i.availableIncentives;

        if (_amount == 0) {
            revert IncentiveTooLow();
        }

        _i.lastClaimDate = block.timestamp;
        _i.claimedIncentives += _amount;
        _i.availableIncentives -= _amount;

        status = token.transfer(_beneficiary, _amount);
        if (!status) {
            revert ClaimFailed();
        }
        emit IncentiveClaimed(_beneficiary, _amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}