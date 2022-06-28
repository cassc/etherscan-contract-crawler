// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
import {IVersion} from "./IVersion.sol";

interface IContractsRegisterEvents {
    // emits each time when new pool was added to register
    event NewPoolAdded(address indexed pool);

    // emits each time when new credit Manager was added to register
    event NewCreditManagerAdded(address indexed creditManager);
}

/// @title Optimised for front-end Address Provider interface
interface IContractsRegister is IContractsRegisterEvents, IVersion {
    //
    // POOLS
    //

    /// @dev Returns array of registered pool addresses
    function getPools() external view returns (address[] memory);

    /// @dev Returns pool address for i-element
    function pools(uint256 i) external returns (address);

    /// @return Returns quantity of registered pools
    function getPoolsCount() external view returns (uint256);

    /// @dev Returns true if address is pool
    function isPool(address) external view returns (bool);

    //
    // CREDIT MANAGERS
    //

    /// @dev Returns array of registered credit manager addresses
    function getCreditManagers() external view returns (address[] memory);

    /// @dev Returns pool address for i-element
    function creditManagers(uint256 i) external returns (address);

    /// @return Returns quantity of registered credit managers
    function getCreditManagersCount() external view returns (uint256);

    /// @dev Returns true if address is pool
    function isCreditManager(address) external view returns (bool);
}