//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';

import '../Modules/INFModule.sol';
import '../Modules/INFModuleWithEvents.sol';

import './INiftyForgeWithModules.sol';

/// @title NiftyForgeWithModules
/// @author Simon Fremaux (@dievardump)
/// @notice These modules can be attached to a contract and enabled/disabled later
///         They can be used to mint elements (need Minter Role) but also can listen
///         To events like MINT, TRANSFER and BURN
///
///         To module developers:
///         Remember cross contract calls have a high cost, and reads too.
///         Do not abuse of Events and only use them if there is a high value to it
///         Gas is not cheap, always think of users first.
contract NiftyForgeWithModules is INiftyForgeWithModules {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    // event emitted whenever a module status changed
    event ModuleChanged(address module);

    // 3 types of events Mint, Transfer and Burn
    EnumerableSetUpgradeable.AddressSet[3] private _listeners;

    // modules list
    // should create a module role instead?
    EnumerableSetUpgradeable.AddressSet internal modules;

    // modules status
    mapping(address => ModuleStatus) public modulesStatus;

    modifier onlyEnabledModule() {
        require(
            modulesStatus[msg.sender] == ModuleStatus.ENABLED,
            '!MODULE_NOT_ENABLED!'
        );
        _;
    }

    /// @notice Helper to list all modules with their state
    /// @return list of modules and status
    function listModules()
        external
        view
        override
        returns (address[] memory list, uint256[] memory status)
    {
        uint256 count = modules.length();
        list = new address[](count);
        status = new uint256[](count);
        for (uint256 i; i < count; i++) {
            list[i] = modules.at(i);
            status[i] = uint256(modulesStatus[list[i]]);
        }
    }

    /// @notice allows a module to listen to events (mint, transfer, burn)
    /// @param eventType the type of event to listen to
    function addEventListener(INFModuleWithEvents.Events eventType)
        external
        override
        onlyEnabledModule
    {
        _listeners[uint256(eventType)].add(msg.sender);
    }

    /// @notice allows a module to stop listening to events (mint, transfer, burn)
    /// @param eventType the type of event to stop listen to
    function removeEventListener(INFModuleWithEvents.Events eventType)
        external
        override
        onlyEnabledModule
    {
        _listeners[uint256(eventType)].remove(msg.sender);
    }

    /// @notice Attach a module
    /// @param module a module to attach
    /// @param enabled if the module is enabled by default
    function _attachModule(address module, bool enabled) internal {
        require(
            modulesStatus[module] == ModuleStatus.UNKNOWN,
            '!ALREADY_ATTACHED!'
        );

        // add to modules list
        modules.add(module);

        // tell the module it's attached
        // making sure module can be attached to this contract
        require(INFModule(module).onAttach(), '!ATTACH_FAILED!');

        if (enabled) {
            _enableModule(module);
        } else {
            _disableModule(module, true);
        }
    }

    /// @dev Allows owner to enable a module (needs to be disabled)
    /// @param module to enable
    function _enableModule(address module) internal {
        require(
            modulesStatus[module] != ModuleStatus.ENABLED,
            '!NOT_DISABLED!'
        );
        modulesStatus[module] = ModuleStatus.ENABLED;

        // making sure module can be enabled on this contract
        require(INFModule(module).onEnable(), '!ENABLING_FAILED!');
        emit ModuleChanged(module);
    }

    /// @dev Disables a module
    /// @param module the module to disable
    /// @param keepListeners a boolean to know if the module can still listen to events
    ///        meaning the module can not interact with the contract anymore but is still working
    ///        for example: a module that transfers an ERC20 to people Minting
    function _disableModule(address module, bool keepListeners)
        internal
        virtual
    {
        require(
            modulesStatus[module] != ModuleStatus.DISABLED,
            '!NOT_ENABLED!'
        );
        modulesStatus[module] = ModuleStatus.DISABLED;

        // we do a try catch without checking return or error here
        // because owners should be able to disable a module any time without the module being ok
        // with it or not
        try INFModule(module).onDisable() {} catch {}

        // remove all listeners if not explicitely asked to keep them
        if (!keepListeners) {
            _listeners[uint256(INFModuleWithEvents.Events.MINT)].remove(module);
            _listeners[uint256(INFModuleWithEvents.Events.TRANSFER)].remove(
                module
            );
            _listeners[uint256(INFModuleWithEvents.Events.BURN)].remove(module);
        }

        emit ModuleChanged(module);
    }

    /// @dev fire events to listeners
    /// @param eventType the type of event fired
    /// @param tokenId the token for which the id is fired
    /// @param from address from
    /// @param to address to
    function _fireEvent(
        INFModuleWithEvents.Events eventType,
        uint256 tokenId,
        address from,
        address to
    ) internal {
        EnumerableSetUpgradeable.AddressSet storage listeners = _listeners[
            uint256(eventType)
        ];
        uint256 length = listeners.length();
        for (uint256 i; i < length; i++) {
            INFModuleWithEvents(listeners.at(i)).onEvent(
                eventType,
                tokenId,
                from,
                to
            );
        }
    }
}