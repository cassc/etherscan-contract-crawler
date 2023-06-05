//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './Modules/INFModuleWithEvents.sol';

/// @title INiftyForgeBase
/// @author Simon Fremaux (@dievardump)
interface INiftyForgeModules {
    enum ModuleStatus {
        UNKNOWN,
        ENABLED,
        DISABLED
    }

    /// @notice Helper to list all modules with their state
    /// @return list of modules and status
    function listModules()
        external
        view
        returns (address[] memory list, uint256[] memory status);

    /// @notice allows a module to listen to events (mint, transfer, burn)
    /// @param eventType the type of event to listen to
    function addEventListener(INFModuleWithEvents.Events eventType) external;

    /// @notice allows a module to stop listening to events (mint, transfer, burn)
    /// @param eventType the type of event to stop listen to
    function removeEventListener(INFModuleWithEvents.Events eventType) external;
}