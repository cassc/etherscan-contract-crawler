// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
import { IVersion } from "./IVersion.sol";

interface IContractsRegisterEvents {
    /// @dev Emits when a new pool is registered in the system
    event NewPoolAdded(address indexed pool);

    /// @dev Emits when a new Credit Manager is registered in the system
    event NewCreditManagerAdded(address indexed creditManager);
}

interface IContractsRegister is IContractsRegisterEvents, IVersion {
    //
    // POOLS
    //

    /// @dev Returns the array of registered pools
    function getPools() external view returns (address[] memory);

    /// @dev Returns a pool address from the list under the passed index
    /// @param i Index of the pool to retrieve
    function pools(uint256 i) external returns (address);

    /// @return Returns the number of registered pools
    function getPoolsCount() external view returns (uint256);

    /// @dev Returns true if the passed address is a pool
    function isPool(address) external view returns (bool);

    //
    // CREDIT MANAGERS
    //

    /// @dev Returns the array of registered Credit Managers
    function getCreditManagers() external view returns (address[] memory);

    /// @dev Returns a Credit Manager's address from the list under the passed index
    /// @param i Index of the Credit Manager to retrieve
    function creditManagers(uint256 i) external returns (address);

    /// @return Returns the number of registered Credit Managers
    function getCreditManagersCount() external view returns (uint256);

    /// @dev Returns true if the passed address is a Credit Manager
    function isCreditManager(address) external view returns (bool);
}