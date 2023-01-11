// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

import { IAccessControlUpgradeable } from "../../lib/openzeppelin-contracts-upgradeable/contracts/access/IAccessControlUpgradeable.sol";

/// @title Interface for CorePermissions
/// @author Recursive Research Inc
interface ICorePermissions is IAccessControlUpgradeable {
    // ----------- Events ---------------------

    /// @dev Emitted when the whitelist is disabled by `admin`.
    event WhitelistDisabled();

    /// @dev Emitted when the whitelist is disabled by `admin`.
    event WhitelistEnabled();

    // ----------- Governor only state changing api -----------

    function createRole(bytes32 role, bytes32 adminRole) external;

    function whitelistAll(address[] memory addresses) external;

    // ----------- GRANTING ROLES -----------

    function disableWhitelist() external;

    function enableWhitelist() external;

    // ----------- Getters -----------

    function GUARDIAN_ROLE() external view returns (bytes32);

    function GOVERN_ROLE() external view returns (bytes32);

    function PAUSE_ROLE() external view returns (bytes32);

    function STRATEGIST_ROLE() external view returns (bytes32);

    function WHITELISTED_ROLE() external view returns (bytes32);

    function whitelistDisabled() external view returns (bool);

    // ----------- Read Interface -----------

    function isWhitelisted(address _address) external view returns (bool);
}