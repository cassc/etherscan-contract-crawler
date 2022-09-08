//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../external/IERC677Receiver.sol";
import "../../external/IERC677Token.sol";

import "../TokenLocker.sol";

enum AccountantPermissions {
    /// @notice 0 is the default value, and the default is no permissions.
    None,
    /// @notice Accountants with this permission can only add incentives.
    Add,
    /// @notice Accountants with this permission can both add and remove incentives.
    Adjust
}

/// @notice Describes a single accountant.
struct AccountantInfo {
    address accountant;
    AccountantPermissions permissions;
}

/// @notice Describes incentives increase for a single liquidity provider.
struct ProviderAddition {
    address provider;
    uint256 amount;
}

/// @notice Describes adjustment of incentives for a single liquidity provider.
struct ProviderAdjustment {
    address provider;
    int256 amount;
}

/// @notice Describes addition of incentives for multiple different liquidity providers, but
///         for a single time interval.
///
///         An accountant might need to generate multiple incentive addition requests for the same
///         interval, if transaction size does not allow to describe all additions in the same
///         call.  All these additions except the very last one should have the `intervalLast` field
///         set to `false`.  And the last adjustment for the range should have it set to `true`.
///
///         It helps the accounting script to find the last complete adjustment that was recorded on
///         the chain.
///
///         In order to make sure that one can check the calculations, accounting script inserts
///         SHA-1 hash of the commit that contained the script into the `scriptSha` field.  This
///         could help validate adjustments.
struct AddIncentives {
    uint64 intervalStart;
    uint64 intervalEnd;
    bool intervalLast;
    bytes20 scriptSha;
    ProviderAddition[] additions;
}

/// @title Contract that handles incentives for liquidity outside of the Futureswap infrastructure.
interface IExternalLiquidityIncentives is IERC677Receiver {
    /// @notice The incentives token that this contract uses.
    function rewardsToken() external view returns (IERC677Token);

    /// @notice When `claim()`ed tokens are moved into this contract for vesting.  We call
    ///         `rewardsToken.transferAndCall()`.
    function tokenLocker() external view returns (TokenLocker);

    /// @notice Addresses that can adjust incentives for the liquidity providers.
    function accountants(address accountant) external returns (AccountantPermissions);

    /// @notice Map a liquidity provider address the amount of `rewardsToken` tokens that they can
    ///         still `claim()`.
    function claimableTokens(address liquidityProvider) external returns (uint256);

    function addAccountant(AccountantInfo calldata info) external;

    function removeAccountant(address accountant) external;

    /// @notice Add tokens to the LP provider balances. This call does not allow any balances to be
    ///         decreased.  The owner contract must have approved for sufficient tokens to be
    ///         transferred from.
    function addIncentives(
        uint64 intervalStart,
        uint64 intervalEnd,
        bool intervalLast,
        bytes20 scriptSha,
        uint256[] calldata packedAccounts
    ) external;

    /// @notice Allows accountants with `AccountantPermissions.Adjust` permissions to redistribute
    ///         incentive balances and/or withdraw the incentive tokens.
    ///
    ///         Note that if incentive balances are adjusted in such a way that there is an excess,
    ///         extra incentives are transferred to the `owner()` address.
    function adjustIncentives(
        uint64 intervalStart,
        uint64 intervalEnd,
        bool intervalLast,
        ProviderAdjustment[] calldata adjustments
    ) external;

    function claim(uint256 lockupTime) external;

    event AccountantAdded(address indexed accountant, AccountantPermissions permimssion);

    event AccountantRemoved(address indexed accountant);

    event IncentivesAdded(
        address indexed accountant,
        uint256 indexed interval,
        bool indexed intervalLast,
        bytes20 scriptSha,
        ProviderAddition[] additions
    );

    event IncentivesAdjusted(
        address indexed accountant,
        uint256 indexed interval,
        bool indexed intervalLast,
        ProviderAdjustment[] adjustments
    );

    /// @notice Event emitted the rewards token is updated.
    /// @param oldRewardsToken The rewards token before the update.
    /// @param newRewardsToken The rewards token after the update.
    event RewardsTokenUpdated(address oldRewardsToken, address newRewardsToken);
}