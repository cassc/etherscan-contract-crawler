// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import {IVault} from "./IVault.sol";
import {HubInfo} from "../libs/LibHub.sol";

/// @title meTokens Protocol Hub Facet interface
/// @author Carter Carlson (@cartercarlson)
interface IHubFacet {
    /// @notice Event of registering a hub
    /// @param id               Unique hub identifer
    /// @param owner            Address to own hub
    /// @param asset            Address of underlying asset
    /// @param vault            Address of vault
    /// @param refundRatio      Rate to refund burners
    /// @param baseY            baseY curve details
    /// @param reserveWeight    reserveWeight curve details
    /// @param encodedVaultArgs Additional encoded vault arguments
    event Register(
        uint256 id,
        address owner,
        address asset,
        address vault,
        uint256 refundRatio,
        uint256 baseY,
        uint32 reserveWeight,
        bytes encodedVaultArgs
    );

    /// @notice Event of making a hub inactive, preventing new subscriptions to the hub
    /// @param id  Unique hub identifier
    event Deactivate(uint256 id);

    /// @notice Event of initializing a hub update
    /// @param id                   Unique hub identifier
    /// @param targetRefundRatio    Target rate to refund burners
    /// @param targetRefundRatio     curve target RefundRatio
    /// @param reconfigure          Boolean to show if we're updating the CurveInfo
    /// @param startTime            Timestamp to start updating
    /// @param endTime              Timestamp to end updating
    /// @param endCooldown          Timestamp to allow another update
    event InitUpdate(
        uint256 id,
        uint256 targetRefundRatio,
        uint32 targetReserveWeight,
        bool reconfigure,
        uint256 startTime,
        uint256 endTime,
        uint256 endCooldown
    );

    /// @notice Event of canceling a hub update
    /// @param id Unique hub identifier
    event CancelUpdate(uint256 id);

    /// @notice Event of transfering hub ownership
    /// @param id          Unique hub identifier
    /// @param newOwner    Address to own the hub
    event TransferHubOwnership(uint256 id, address newOwner);

    /// @notice Event of finishing a hub update
    /// @param id Unique hub identifier
    event FinishUpdate(uint256 id);

    /// @notice Register a new hub
    /// @dev Only callable by RegisterController
    /// @param owner            Address to own hub
    /// @param asset            Address of vault asset
    /// @param vault            Address of vault
    /// @param refundRatio      Rate to refund burners
    /// @param baseY            baseY curve details
    /// @param reserveWeight    reserveWeight curve details
    /// @param encodedVaultArgs Additional encoded vault arguments
    function register(
        address owner,
        address asset,
        IVault vault,
        uint256 refundRatio,
        uint256 baseY,
        uint32 reserveWeight,
        bytes memory encodedVaultArgs
    ) external;

    /// @notice Deactivate a hub, which prevents a meToken from subscribing
    ///     to it
    /// @dev Only callable by hub owner or DeactivateController
    /// @param id Unique hub identifier
    function deactivate(uint256 id) external;

    /// @notice Intialize a hub update
    /// @dev Only callable by hub owner
    /// @param id                   Unique hub identifier
    /// @param targetRefundRatio    Target rate to refund burners
    /// @param targetReserveWeight  Target curve reserveWeight
    function initUpdate(
        uint256 id,
        uint256 targetRefundRatio,
        uint32 targetReserveWeight
    ) external;

    /// @notice Cancel a hub update
    /// @dev Can only be called before startTime
    /// @dev Only callable by hub owner
    /// @param id Unique hub identifier
    function cancelUpdate(uint256 id) external;

    /// @notice Finish updating a hub
    /// @dev Callable by anyone
    /// @param id  Unique hub identifier
    function finishUpdate(uint256 id) external;

    /// @notice Transfer the ownership of a hub
    /// @dev Only callable by hub owner
    /// @param id       Unique hub identifier
    /// @param newOwner Address to own the hub
    function transferHubOwnership(uint256 id, address newOwner) external;

    /// @notice Get the time period for a hub to warmup, which is the time
    ///     difference between initUpdate() is called and when the update
    ///     is live
    /// @dev Only callable by DurationsController
    /// @dev Is greater than meToken warmup + duration + 1 day
    /// @param period   Period of time, in seconds
    function setHubWarmup(uint256 period) external;

    /// @notice Set the time period for a hub to update, which is the time
    ///     difference between when the update is live and when finishUpdate()
    ///     can be called
    /// @dev Only callable by DurationsController
    /// @param period   Period of time, in seconds
    function setHubDuration(uint256 period) external;

    /// @notice Set the time period for a hub to cooldown, which is the time
    ///     difference between when finishUpdate() can be called and when initUpdate()
    ///     can be called again
    /// @dev Only callable by DurationsController
    /// @param period   Period of time, in seconds
    function setHubCooldown(uint256 period) external;

    /// @notice View to get basic information for a hub - reducing gas if called on-chain
    /// @param id           Unique hub identifier
    /// @return refundRatio Rate to refund burners
    /// @return owner       Address which owns hub
    /// @return vault       Address of vault
    /// @return asset       Address of vault asset
    /// @return updating    Boolean to show if hub is in state of updating
    /// @return active      Boolean to show if hub is live and usable
    function getBasicHubInfo(uint256 id)
        external
        view
        returns (
            uint256 refundRatio,
            address owner,
            address vault,
            address asset,
            bool updating,
            bool active
        );

    /// @notice View to get information for a hub
    /// @param id Unique hub identifier
    /// @return Information of hub
    function getHubInfo(uint256 id) external view returns (HubInfo memory);

    /// @notice Counter of hubs registered
    /// @return uint256 Unique hub count
    function count() external view returns (uint256);

    /// @notice Get the hub update warmup period
    /// @return Period of hub update warmup, in seconds
    function hubWarmup() external view returns (uint256);

    /// @notice Get the hub update duration period
    /// @return Period of hub update duration, in seconds
    function hubDuration() external view returns (uint256);

    /// @notice Get the hub update cooldown period
    /// @return Period of hub update cooldown, in seconds
    function hubCooldown() external view returns (uint256);
}