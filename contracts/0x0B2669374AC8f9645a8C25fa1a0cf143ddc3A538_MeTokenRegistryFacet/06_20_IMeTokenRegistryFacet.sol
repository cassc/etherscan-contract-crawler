// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import {MeTokenInfo} from "../libs/LibMeToken.sol";

/// @title meTokens Protocol MeToken Registry interface
/// @author Carter Carlson (@cartercarlson)
interface IMeTokenRegistryFacet {
    /// @notice Event of subscribing (creating) a new meToken
    /// @param meToken         Address of created meToken
    /// @param owner           Address of meToken owner
    /// @param minted          Amount of meToken minted to owner
    /// @param asset           Address of underlying asset
    /// @param assetsDeposited Amount of assets deposited
    /// @param name            Name of meToken
    /// @param symbol          Symbol of meToken
    /// @param hubId           Unique hub identifier
    event Subscribe(
        address indexed meToken,
        address indexed owner,
        uint256 minted,
        address asset,
        uint256 assetsDeposited,
        string name,
        string symbol,
        uint256 hubId
    );

    /// @notice Event of initializing a meToken subscription to a different hub
    /// @param meToken                 Address of meToken
    /// @param targetHubId             Target hub to suscribe to
    /// @param migration               Address of migration vault
    /// @param encodedMigrationArgs    additional encoded migration vault arguments
    event InitResubscribe(
        address indexed meToken,
        uint256 targetHubId,
        address migration,
        bytes encodedMigrationArgs
    );

    /// @notice Event of canceling a meToken resubscription
    /// @param meToken Address of meToken
    event CancelResubscribe(address indexed meToken);

    /// @notice Event of finishing a meToken resubscription
    /// @param meToken address of meToken
    event FinishResubscribe(address indexed meToken);

    /// @notice Event of updating a meToken's balancePooled
    /// @param add     boolean that is true if adding to balance, false if subtracting
    /// @param meToken address of meToken
    /// @param amount  amount to add/subtract
    event UpdateBalancePooled(bool add, address meToken, uint256 amount);

    /// @notice Event of updating a meToken's balanceLocked
    /// @param add     boolean that is true if adding to balance, false if subtracting
    /// @param meToken address of meToken
    /// @param amount  amount to add/subtract
    event UpdateBalanceLocked(bool add, address meToken, uint256 amount);

    /// @notice Event of updating a meToken's balancePooled and balanceLocked
    /// @param meToken     Address of meToken
    /// @param newBalance  Rate to multiply balances by
    event UpdateBalances(address meToken, uint256 newBalance);

    /// @notice Event of transfering meToken ownership to a new owner
    /// @param from    Address of current meToken owner
    /// @param to      Address to own the meToken
    /// @param meToken Address of meToken
    event TransferMeTokenOwnership(address from, address to, address meToken);

    /// @notice Event of cancelling the transfer of meToken ownership
    /// @param from    Address of current meToken owner
    /// @param meToken Address of meToken
    event CancelTransferMeTokenOwnership(address from, address meToken);

    /// @notice Event of claiming the transfer of meToken ownership
    /// @param from    Address of current meToken owner
    /// @param to      Address to own the meToken
    /// @param meToken Address of meToken
    event ClaimMeTokenOwnership(address from, address to, address meToken);

    /// @notice Create and subscribe a meToken to a hub
    /// @param name            Name of meToken
    /// @param symbol          Symbol of meToken
    /// @param hubId           Initial hub to subscribe to
    /// @param assetsDeposited Amount of assets deposited at meToken initialization
    function subscribe(
        string calldata name,
        string calldata symbol,
        uint256 hubId,
        uint256 assetsDeposited
    ) external;

    /// @notice Initialize a meToken resubscription to a new hub
    /// @dev Only callable by meToken owner
    /// @param meToken                 Address of meToken
    /// @param targetHubId             Hub which meToken is resubscribing to
    /// @param migration               Address of migration vault
    /// @param encodedMigrationArgs    Additional encoded migration vault arguments
    function initResubscribe(
        address meToken,
        uint256 targetHubId,
        address migration,
        bytes memory encodedMigrationArgs
    ) external;

    /// @notice Cancel a meToken resubscription
    /// @dev Can only be done during the warmup period
    /// @dev Only callable by meToken owner
    /// @param meToken Address of meToken
    function cancelResubscribe(address meToken) external;

    /// @notice Finish a meToken's resubscription to a new hub
    /// @dev Callable by anyone
    /// @param meToken  Address of meToken
    /// @return         Details of meToken
    function finishResubscribe(address meToken)
        external
        returns (MeTokenInfo memory);

    /// @notice Update a meToken's balanceLocked and balancePooled
    /// @dev Only callable by migration contract
    /// @param meToken     Address of meToken
    /// @param newBalance  Resulting balance from migration vault
    function updateBalances(address meToken, uint256 newBalance) external;

    /// @notice Transfer meToken ownership to a new owner
    /// @dev Only callable by meToken owner
    /// @param newOwner Address to claim meToken ownership of msg.sender
    function transferMeTokenOwnership(address newOwner) external;

    /// @notice Cancel the transfer of meToken ownership
    /// @dev Only callable by meToken owner
    function cancelTransferMeTokenOwnership() external;

    /// @notice Claim the transfer of meToken ownership
    /// @dev Only callable by recipient
    /// @param from Address of current meToken owner
    function claimMeTokenOwnership(address from) external;

    /// @notice Set the time period for a meToken to warmup, which is the time
    ///     difference between when initResubscribe() is called and when the
    ///     resubscription is live
    /// @dev Only callable by DurationsController
    /// @param period Period of the meToken resubscribe warmup, in seconds
    function setMeTokenWarmup(uint256 period) external;

    /// @notice Set the time period for a meToken to resubscribe, which is the time
    ///     difference between when the resubscription is live and when
    ///     finishResubscription() can be called
    /// @dev Only callable by DurationsController
    /// @param period Period of the meToken resubscribe duration, in seconds
    function setMeTokenDuration(uint256 period) external;

    /// @notice View to get basic information for a meToken - reducing gas if called on-chain
    /// @param meToken          Address of meToken queried
    /// @return owner           Address of meToken owner
    /// @return hubId           Unique hub identifier
    /// @return balancePooled   Amount of balance pooled
    /// @return balanceLocked   Amount of balance locked
    /// @return migration       Address of migration vault
    function getBasicMeTokenInfo(address meToken)
        external
        view
        returns (
            address owner,
            uint256 hubId,
            uint256 balancePooled,
            uint256 balanceLocked,
            address migration
        );

    /// @notice View to get information for a meToken
    /// @param meToken      Address of meToken queried
    /// @return meToken     Details of meToken
    function getMeTokenInfo(address meToken)
        external
        view
        returns (MeTokenInfo memory);

    /// @notice View to return Address of meToken owned by owner
    /// @param owner    Address of meToken owner
    /// @return         Address of meToken
    function getOwnerMeToken(address owner) external view returns (address);

    /// @notice View to see the address to claim meToken ownership from
    /// @param from Address to transfer meToken ownership
    /// @return     Address of pending meToken owner
    function getPendingOwner(address from) external view returns (address);

    /// @notice Get the meToken resubscribe warmup period
    /// @return Period of meToken resubscribe warmup, in seconds
    function meTokenWarmup() external view returns (uint256);

    /// @notice Get the meToken resubscribe duration period
    /// @return Period of the meToken resubscribe duration, in seconds
    function meTokenDuration() external view returns (uint256);

    /// @notice View to return if an address owns a meToken or not
    /// @param owner    Address to query
    /// @return         True if owns a meToken, else false
    function isOwner(address owner) external view returns (bool);
}