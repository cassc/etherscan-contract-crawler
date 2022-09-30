// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title meTokens Protocol Ownership Facet interface
/// @author Carter Carlson (@cartercarlson)
interface IOwnershipFacet {
    /// @notice Set Diamond Controller
    /// @dev Only callable by DiamondController
    /// @param newController Address of new DiamondController
    function setDiamondController(address newController) external;

    /// @notice Set trusted forwarder for meta transactions
    /// @dev Only callable by DiamondController
    /// @param forwarder Address of new trusted forwarder
    function setTrustedForwarder(address forwarder) external;

    /// @notice Set Fees Controller
    /// @dev Only callable by FeesController
    /// @param newController Address of new FeesController
    function setFeesController(address newController) external;

    /// @notice Set Durations Controller
    /// @dev Only callable by DurationsController
    /// @param newController Address of new DurationsController
    function setDurationsController(address newController) external;

    /// @notice Set Register Controller
    /// @dev Only callable by RegisterController
    /// @param newController Address of new RegisterController
    function setRegisterController(address newController) external;

    /// @notice Set Deactivate Controller
    /// @dev Only callable by DeactivateController
    /// @param newController Address of new DeactivateController
    function setDeactivateController(address newController) external;

    /// @notice Get trustedForwarder
    /// @return address trustedForwarder
    function trustedForwarder() external view returns (address);

    /// @notice Get diamondController
    /// @return address diamondController
    function diamondController() external view returns (address);

    /// @notice Get feesController
    /// @return address feesController
    function feesController() external view returns (address);

    /// @notice Get durationsController
    /// @return address durationsController
    function durationsController() external view returns (address);

    /// @notice Get registerController
    /// @return address registerController
    function registerController() external view returns (address);

    /// @notice Get deactivateController
    /// @return address deactivateController
    function deactivateController() external view returns (address);
}