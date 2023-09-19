// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IPaymentPlan Interface
/// @notice Interface for the PaymentPlan contract
interface IPaymentPlan {

    // Errors
    error NotSubscribed(address);
    error AlreadySubscribed(address);
    error InvalidReferral(string);
    error ReferralCodeTaken(string);
    error UnsupportedPaymentToken(address);
    error InvalidTimePeriod(uint8);
    error NullAddress(address);
    error NotEnoughFunds(uint256);
    error PaymentFailed();
    error WithdrawFailed();
    error FeeTooHigh(uint256);
    error NonExistentPlan(string);

    // Events
    event ReferralRegistered(address indexed beneficiary, string code);
    event SubscriptionExtended(string invoice, address indexed purchaser, uint128 indexed expiry);
    event SubscriptionCreated(string invoice, string code, address indexed purchaser, uint128 indexed expiry);

    // Structs
    struct Plan {
        uint128 price;
        uint128 length;
    }

    struct Subscription {
        Plan plan;
        uint128 expiration;
    }

    /// @notice Fetch the latest ETH price
    /// @return The latest ETH price
    function getLatestETHPrice() external view returns (int);

    /// @notice Subscribe or renew a subscription
    /// @param invoice The invoice reference
    /// @param planId The plan ID to subscribe
    /// @param token The token used for payment
    /// @param code The referral code (if any)
    function subscribe(string calldata invoice, string calldata planId, address token, string calldata code) external payable;

    /// @notice Renew a subscription
    /// @param invoice The invoice reference
    /// @param planId The plan ID to renew
    /// @param token The token used for payment
    function renewSubscription(string calldata invoice, string calldata planId, address token) external payable;

    /// @notice Register a referral code
    /// @param code The referral code to register
    function registerReferral(string calldata code) external;

    /// @notice Set or update a plan
    /// @param planId The plan ID to set or update
    /// @param plan The details of the plan
    function setPlan(string calldata planId, Plan calldata plan) external;

    /// @notice Update the team wallet address
    /// @param newWallet The new team wallet address
    function updateTeamWallet(address newWallet) external;

    /// @notice Update a user's subscription
    /// @param user The user's address
    /// @param newSubscription The new subscription details
    function updateUserSubscription(address user, Subscription calldata newSubscription) external;

    /// @notice Update the referral fee percentage
    /// @param newFee The new fee percentage
    function updateReferralFee(uint256 newFee) external;

    /// @notice Withdraw funds (either ETH or tokens)
    /// @param token The token address or 0 for ETH
    function withdraw(address token) external;
}