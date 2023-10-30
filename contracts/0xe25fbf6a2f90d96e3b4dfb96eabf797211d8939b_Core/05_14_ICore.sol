// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

import "./ICorePermissions.sol";

/// @notice Interface for Core
/// @author Recursive Research Inc
interface ICore is ICorePermissions {
    // ----------- Events ---------------------

    /// @dev Emitted when the protocol fee (`protocolFee`) is changed
    ///   out of core.MAX_FEE()
    event ProtocolFeeUpdated(uint256 protocolFee);

    /// @dev Emitted when the protocol fee destination (`feeTo`) is changed
    event FeeToUpdated(address indexed feeTo);

    /// @dev Emitted when the pause is triggered
    event Paused();

    /// @dev Emitted when the pause is lifted
    event Unpaused();

    // @dev Emitted when a vault with address `vault`
    event VaultRegistered(address indexed vault);

    // @dev Emitted when a vault with address `vault`
    event VaultRemoved(address indexed vault);

    // ----------- Default Getters --------------

    /// @dev constant set to 10_000
    function MAX_FEE() external view returns (uint256);

    function feeTo() external view returns (address);

    /// @dev protocol fee out of core.MAX_FEE()
    function protocolFee() external view returns (uint256);

    function wrappedNative() external view returns (address);

    // ----------- Main Core Utility --------------

    function registerVaults(address[] memory vaults) external;

    function removeVaults(address[] memory vaults) external;

    /// @dev set core.protocolFee, out of core.MAX_FEE()
    function setProtocolFee(uint256 _protocolFee) external;

    function setFeeTo(address _feeTo) external;

    // ----------- Protocol Pausing -----------

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool);
}