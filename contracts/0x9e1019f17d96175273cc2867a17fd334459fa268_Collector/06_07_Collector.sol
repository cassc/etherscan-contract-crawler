// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';

import './interfaces/ICollector.sol';

/// Must be called by the beneficiary address
error OnlyBeneficiary();

/// Must not be zero address.
error NoAddressZero();

/// @title Collector
/// @author Giveth developers
/// @notice A simple collection contract that allows the beneficiary to withdraw collected ETH and ERC-20 tokens.
contract Collector is ICollector, Ownable {
    ///
    /// STATE:
    ///

    address internal _beneficiary;

    ///
    /// MODIFIERS:

    modifier onlyBeneficiary() {
        if (msg.sender != _beneficiary) {
            revert OnlyBeneficiary();
        }
        _;
    }

    ///
    /// CONSTRUCTOR:
    ///

    /// @dev Construct the collector, set the owner and beneficiary
    /// @param ownerAddr Address that will own the contract
    /// @param beneficiaryAddr Address that will be the beneficiary
    constructor(address ownerAddr, address beneficiaryAddr) {
        _beneficiary = beneficiaryAddr;
        _transferOwnership(ownerAddr);
    }

    ///
    /// FALLBACK/RECEIVE;
    ///

    /// @dev Contract collects ETH and emits a collected event.
    receive() external payable {
        emit Collected(msg.sender, msg.value);
    }

    ///
    /// ADMIN FUNCTIONS:
    ///

    /// @inheritdoc ICollector
    function changeBeneficiary(address beneficiaryAddr) external onlyOwner {
        if (beneficiaryAddr == address(0)) {
            revert NoAddressZero();
        }
        address oldBeneficiary = _beneficiary;
        _beneficiary = beneficiaryAddr;
        emit BeneficiaryChanged(oldBeneficiary, _beneficiary);
    }

    ///
    /// EXTERNAL FUNCTIONS:
    ///

    /// @inheritdoc ICollector
    function withdraw() external onlyBeneficiary {
        emit Withdrawn(msg.sender, address(this).balance);
        Address.sendValue(payable(_beneficiary), address(this).balance);
    }

    /// @inheritdoc ICollector
    function withdrawTokens(address token) external onlyBeneficiary {
        uint256 balance = IERC20(token).balanceOf(address(this));
        emit WithdrawnTokens(token, msg.sender, balance);
        SafeERC20.safeTransfer(IERC20(token), _beneficiary, balance);
    }

    ///
    /// VIEW FUNCTIONS:
    ///

    /// @inheritdoc ICollector
    function beneficiary() external view returns (address) {
        return _beneficiary;
    }
}