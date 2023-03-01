// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {IObservability, IObservabilityEvents} from "./interface/IObservability.sol";

contract Observability is IObservability, IObservabilityEvents {
    /// @notice Emitted when a new clone is deployed
    function emitCloneDeployed(address owner, address clone) external override {
        emit CloneDeployed(msg.sender, owner, clone);
    }

    /// @notice Emitted when a sale has occured
    function emitSale(
        address to,
        uint256 pricePerToken,
        uint256 amount
    ) external override {
        emit Sale(msg.sender, to, pricePerToken, amount);
    }

    /// @notice Emitted when funds have been withdrawn
    function emitFundsWithdrawn(
        address withdrawnBy,
        address withdrawnTo,
        uint256 amount
    ) external override {
        emit FundsWithdrawn(msg.sender, withdrawnBy, withdrawnTo, amount);
    }

    /// @notice Emitted when a new implementation is registered
    function emitDeploymentTargetRegistererd(address impl) external override {
        emit DeploymentTargetRegistered(impl);
    }

    /// @notice Emitted when an implementation is unregistered
    function emitDeploymentTargetUnregistered(address impl) external override {
        emit DeploymentTargetUnregistered(impl);
    }

    /// @notice Emitted when a new upgrade is registered
    function emitUpgradeRegistered(
        address prevImpl,
        address impl
    ) external override {
        emit UpgradeRegistered(prevImpl, impl);
    }

    /// @notice Emitted when an upgrade is unregistered
    function emitUpgradeUnregistered(
        address prevImpl,
        address impl
    ) external override {
        emit UpgradeUnregistered(prevImpl, impl);
    }
}