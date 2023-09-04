// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Fellowship

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Payment Distributor
/// @notice Distributes tokens to payees according to their shares
/// @dev While `owner` already has full control, this contract uses `ReentrancyGuard` to prevent any footgun shenanigans
///  that could result from calling `setShares` during `withdraw`
contract PaymentDistributor is Ownable, ReentrancyGuard {
    uint256 private shareCount;
    address[] private payees;
    mapping(address => PayeeInfo) private payeeInfo;

    struct PayeeInfo {
        uint128 index;
        uint128 shares;
    }

    error NoBalance();
    error PaymentsNotConfigured();
    error OnlyPayee();
    error FailedPaying(address payee, bytes data);

    /// @dev Check that caller is owner or payee
    modifier onlyPayee() {
        if (shareCount == 0) revert PaymentsNotConfigured();
        if (msg.sender != owner()) {
            // Get the stored index for the sender
            uint256 index = payeeInfo[msg.sender].index;
            // Check that they are actually at that index
            if (payees[index] != msg.sender) revert OnlyPayee();
        }

        _;
    }

    modifier paymentsConfigured() {
        if (shareCount == 0) revert PaymentsNotConfigured();
        _;
    }

    receive() external payable {}

    // PAYEE FUNCTIONS

    /// @notice Distributes the balance of this contract to the `payees`
    function withdraw() external onlyPayee nonReentrant {
        // CHECKS: don't bother with zero transfers
        uint256 shareSplit = address(this).balance / shareCount;
        if (shareSplit == 0) revert NoBalance();

        // INTERACTIONS
        bool success;
        bytes memory data;
        for (uint256 i = 0; i < payees.length; i++) {
            address payee = payees[i];
            unchecked {
                (success, data) = payee.call{value: shareSplit * payeeInfo[payee].shares}("");
            }
            if (!success) revert FailedPaying(payee, data);
        }
    }

    /// @notice Distributes tokens held by this contract to the `payees`
    function withdrawToken(IERC20 token) external onlyPayee nonReentrant {
        // CHECKS inputs
        require(address(token).code.length > 0, "Token address must be a contract");
        // INTERACTIONS: external call to get token balance, then pass off to _withdrawToken for the transfers
        _withdrawToken(token, token.balanceOf(address(this)));
    }

    /// @notice Distributes a fixed number of tokens held by this contract to the `payees`
    /// @dev Safety measure for exotic ERC20 contracts that charge a fee in addition to transfer, or other cases where
    ///  the whole balance may not be transferable.
    function withdrawToken(IERC20 token, uint256 balance) external onlyPayee nonReentrant {
        // CHECKS inputs
        require(address(token).code.length > 0, "Token address must be a contract");
        // INTERACTIONS: pass off to _withdrawToken for transfers
        _withdrawToken(token, balance);
    }

    // OWNER FUNCTIONS

    /// @notice Sets `payees_` who receive funds from this contract in accordance with shares in the `shares` array
    /// @dev `payees_` and `shares` must have the same length and non-zero values
    function setShares(address[] calldata payees_, uint128[] calldata shares) external onlyOwner nonReentrant {
        // CHECKS inputs
        require(payees_.length > 0, "Must set at least one payee");
        require(payees_.length < type(uint128).max, "Too many payees");
        require(payees_.length == shares.length, "Payees and shares must have the same length");

        // CHECKS + EFFECTS: check each payee before setting values
        shareCount = 0;
        payees = payees_;
        unchecked {
            // Unchecked arithmetic: already checked that the number of payees is less than uint128 max
            for (uint128 i = 0; i < payees_.length; i++) {
                address payee = payees_[i];
                uint128 payeeShares = shares[i];
                require(payee != address(0), "Payees must not be the zero address");
                require(payeeShares > 0, "Payees shares must not be zero");

                // Unchecked arithmetic: since number of payees is less than uint128 max and share values are uint128,
                // `shareCount` cannot exceed uint256 max.
                shareCount += payeeShares;
                PayeeInfo storage info = payeeInfo[payee];
                info.index = i;
                info.shares = payeeShares;
            }
        }
    }

    // PRIVATE FUNCTIONS

    function _withdrawToken(IERC20 token, uint256 balance) private {
        // CHECKS: don't bother with zero transfers
        uint256 shareSplit = balance / shareCount;
        if (shareSplit == 0) revert NoBalance();

        // INTERACTIONS
        for (uint256 i = 0; i < payees.length; i++) {
            address payee = payees[i];

            // Based on token/ERC20/utils/SafeERC20.sol and utils/Address.sol from OpenZeppelin Contracts v4.7.0
            (bool success, bytes memory data) = address(token).call(
                abi.encodeWithSelector(token.transfer.selector, payee, shareSplit * payeeInfo[payee].shares)
            );
            if (!success) {
                if (data.length > 0) revert FailedPaying(payee, data);
                revert FailedPaying(payee, "Transfer reverted");
            } else if (data.length > 0 && !abi.decode(data, (bool))) {
                revert FailedPaying(payee, "Transfer failed");
            }
        }
    }
}