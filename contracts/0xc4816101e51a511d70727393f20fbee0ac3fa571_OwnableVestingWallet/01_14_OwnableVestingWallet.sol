// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import { VestingWalletUpgradeable } from "./VestingWalletUpgradeable.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title OwanableVestingWallet
 * @dev Openzeppelin's VestingWallet combined with Ownable2Step
 * which owner have privilege to withdraw
 */
contract OwnableVestingWallet is VestingWalletUpgradeable, Ownable2StepUpgradeable {
    event OwnerWithdrawn(address owner, address token, uint256 amount);
    event BeneficiaryChanged(address oldBeneficiary, address newBeneficiary);

    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Set the beneficiary, start timestamp and vesting duration, and owner of the vesting wallet.
     */
    function initialize(
        address beneficiaryAddress,
        uint64 startTimestamp,
        uint64 durationSeconds,
        address owner_
    ) public initializer {
        __VestingWallet_init(beneficiaryAddress, startTimestamp, durationSeconds);
        _transferOwnership(owner_);
    }

    /**
     * @dev Withdraw all token from the wallet
     */
    function withdraw(address token) external onlyOwner {
        uint256 transferAmount = IERC20(token).balanceOf(address(this));
        SafeERC20.safeTransfer(IERC20(token), msg.sender, transferAmount);
        emit OwnerWithdrawn(msg.sender, token, transferAmount);
    }

    /**
     * @dev Change beneficiary
     */
    function changeBeneficiary(address newBeneficiary) external onlyOwner {
        address oldBeneficiary = _beneficiary;
        _beneficiary = newBeneficiary;
        emit BeneficiaryChanged(oldBeneficiary, newBeneficiary);
    }
}