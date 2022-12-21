// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

/// @notice GhostMarket Incentives Contract
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
    /// @notice max transactions per top up
    uint256 public maxPerBatch;

    /// @notice address of token used for incentives rewards
    IERC20Upgradeable public token;

    /// @notice balance of token used for incentives rewards
    uint256 public reserveBalance;

    /// @notice beneficiary to incentive mapping
    mapping(address => Incentive) public incentives;

    // ==========EVENTS============
    /// @notice This event is emitted when incentives are persisted
    /// @param beneficiary beneficiary of the incentives
    /// @param amount amount persisted for the beneficiary
    event IncentivePersisted(address beneficiary, uint256 amount);

    /// @notice This event is emitted when incentives are claimed
    /// @param beneficiary beneficiary of the incentives
    /// @param amount amount claimed by the beneficiary
    event IncentiveClaimed(address indexed beneficiary, uint256 amount);

    /// @notice This event is emitted when incentives are refilled
    /// @param from address that triggered it
    /// @param amount amount refilled
    event TopUp(address indexed from, uint256 amount);

    // ==========ERRORS============
    /// @notice This error is emitted when trying to claim and transfer failed
    error ClaimFailed();

    /// @notice This event is emitted when trying to topup and transfer failed
    error TopUpFailed();

    /// @notice This event is emitted when trying to claim and user balance is 0
    error IncentiveTooLow();

    /// @notice This event is emitted when trying to persist incentive and amount is < reserveBalance
    error InsufficientReserveBalance();

    /// @notice This event is emitted when trying to persist incentive and incorect sender
    error NotOwnedIncentive();

    /// @notice Initialize the contract
    /// @dev sets the token instance to be used in this contract.
    /// @param _token IERC20Upgradeable token to be used as incentive
    function initialize(IERC20Upgradeable _token) public initializer {
        __Ownable_init();
        token = _token;
        maxPerBatch = 10000;
    }

    /// @notice Top up incentives
    /// @param _amount to transfer from sender
    /// @dev uses the ERC20 transferFrom for token transfer,
    ///      allowance must be given to the contract ahead of time.
    /// @return status boolean value for transaction activity
    function topUp(uint256 _amount) external returns (bool status) {
        status = token.transferFrom(msg.sender, address(this), _amount);
        if (!status) {
            revert TopUpFailed();
        }
        reserveBalance += _amount;
        emit TopUp(msg.sender, _amount);
    }

    /// @notice Top up single incentive for claiming
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

    /// @notice Top up multiple incentives for claiming
    /// @param _beneficiaries to add incentive to, create if not exist
    /// @param _amounts to add to the incentive
    function batchAddAmountToIncentive(address[] memory _beneficiaries, uint256[] memory _amounts) external onlyOwner {
        require(_beneficiaries.length <= maxPerBatch, "batch too much");
        require(_beneficiaries.length == _amounts.length, "Unequal beneficiaries and amounts counts");
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            addAmountToIncentive(_beneficiaries[i], _amounts[i]);
        }
    }

    /// @notice Allows beneficiary to claim an incentive
    /// @dev transfer specified amount to valid incentive beneficiary. incentive is persisted to reflect claim.
    /// @return status boolean value for transaction activity
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

    /// @notice Pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }
}