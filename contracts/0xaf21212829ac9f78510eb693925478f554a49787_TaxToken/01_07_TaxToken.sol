// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

contract TaxToken is ERC20, Ownable2Step {
    // =============================================================
    //                       ERRORS
    // =============================================================

    error FeeTooHigh();
    error ZeroAddress();
    error MaxTransferAmountExceeded();
    error NotAuthorized();

    // =============================================================
    //                       EVENTS
    // =============================================================

    event FeeRecipientUpdated(address newFeeRecipient);
    event FeeUpdated(uint256 fee);
    event MaxTransferAmountUpdated(uint256 amount);
    event TaxedStatusUpdated(address account, bool isTaxed);
    event ExcludedStatusUpdated(address account, bool isExcluded);
    event BlacklistedStatusUpdated(address account, bool isBlacklisted);

    // =============================================================
    //                       STORAGE
    // =============================================================

    /// @notice the fee recipient
    address public feeRecipient;

    /// @notice the fee
    uint256 public fee;

    /// @notice the max transfer amount
    uint256 public maxTransferAmount;

    /// @notice mapping of addresses that are taxed
    mapping(address => bool) public taxed;

    /// @notice mapping of addresses that are excluded from fee
    mapping(address => bool) public excludedFromFee;

    /// @notice mapping of addresses that are blacklisted
    mapping(address => bool) public blacklisted;

    // =============================================================
    //                       CONSTRUCTOR
    // =============================================================

    constructor(
        address owner_,
        uint256 fee_,
        address feeRecipient_,
        uint256 initialSupply,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {
        if (owner_ == address(0) || feeRecipient_ == address(0)) revert ZeroAddress();
        if (fee_ > 10000) revert FeeTooHigh();

        // transfer ownership to owner
        _transferOwnership(owner_);

        // set fee
        fee = fee_;

        // set fee recipient
        feeRecipient = feeRecipient_;

        // exclude addresses from fees
        excludedFromFee[owner_] = true;
        excludedFromFee[feeRecipient_] = true;

        // mint initial supply to owner
        _mint(owner_, initialSupply);
    }

    // =============================================================
    //                       RESTRICTED FUNCTIONS
    // =============================================================

    /// @notice Allows the owner to set the fee
    /// @param newFee the new fee, in basis points
    function setFee(uint256 newFee) external onlyOwner {
        if (newFee > 10000) revert FeeTooHigh();
        fee = newFee;
        emit FeeUpdated(newFee);
    }

    /// @notice Allows the owner to set the fee recipient
    /// @param newFeeRecipient the new fee recipient
    function setFeeRecipient(address newFeeRecipient) external onlyOwner {
        if (newFeeRecipient == address(0)) revert ZeroAddress();
        feeRecipient = newFeeRecipient;
        emit FeeRecipientUpdated(newFeeRecipient);
    }

    /// @notice Allows the owner to exclude or include fees for an account
    /// @param account the account to update excluded status for
    /// @param isExcluded the new excluded status
    function setExcluded(address account, bool isExcluded) external onlyOwner {
        excludedFromFee[account] = isExcluded;
        emit ExcludedStatusUpdated(account, isExcluded);
    }

    /// @notice Allows the owner to set the max transfer amount
    /// @param amount the new max transfer amount
    function setMaxTransferAmount(uint256 amount) external onlyOwner {
        maxTransferAmount = amount;
        emit MaxTransferAmountUpdated(amount);
    }

    /// @notice Allows the owner to update the blacklisted status of an account
    /// @param account the account to update blacklist status for
    /// @param isBlacklisted the new blacklist status
    function setBlacklisted(address account, bool isBlacklisted) external onlyOwner {
        blacklisted[account] = isBlacklisted;
        emit BlacklistedStatusUpdated(account, isBlacklisted);
    }

    /// @notice Allows the owner to update the taxed status of an account
    /// @param account the account to update taxed status for
    /// @param isTaxed the new taxed status
    function setTaxed(address account, bool isTaxed) external onlyOwner {
        taxed[account] = isTaxed;
        emit TaxedStatusUpdated(account, isTaxed);
    }

    // =============================================================
    //                       INTERNAL FUNCTIONS
    // =============================================================

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);

        // check if either account is blacklisted
        if (blacklisted[from] || blacklisted[to]) revert NotAuthorized();

        // enforce max transfer amount if neither account is owner
        if (from != owner() && to != owner()) {
            if (amount > maxTransferAmount) revert MaxTransferAmountExceeded();
        }
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        //indicates if fee should be deducted from transfer
        bool takeFee = (taxed[from] || taxed[to]);

        //if any account belongs to excludedFromFee account then remove the fee
        if (excludedFromFee[from] || excludedFromFee[to]) {
            takeFee = false;
        }

        if (takeFee) {
            //calculate fee amount
            uint256 feeAmount = amount * fee / 10000;
            //transfer to fee recipient
            super._transfer(from, feeRecipient, feeAmount);
            // transfer remaining amount to "to" address
            super._transfer(from, to, amount - feeAmount);
        } else {
            super._transfer(from, to, amount);
        }
    }
}