// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import {IContractsRegister} from "../interfaces/IContractsRegister.sol";

import {Errors} from "../libraries/Errors.sol";
import {ACLTrait} from "./ACLTrait.sol";

/// @title Pools & Contract managers registry
/// @notice Keeps pools & contract manager addresses
contract ContractsRegister is IContractsRegister, ACLTrait {
    // Pools list
    address[] public override pools;
    mapping(address => bool) public override isPool;

    // Credit Managers list
    address[] public override creditManagers;
    mapping(address => bool) public override isCreditManager;

    // Contract version
    uint256 public constant version = 1;

    constructor(address addressProvider) ACLTrait(addressProvider) {}

    /// @dev Adds pool to list
    /// @param newPoolAddress Address on new pool added
    function addPool(address newPoolAddress)
        external
        configuratorOnly // T:[CR-1]
    {
        require(
            newPoolAddress != address(0),
            Errors.ZERO_ADDRESS_IS_NOT_ALLOWED
        );
        require(!isPool[newPoolAddress], Errors.CR_POOL_ALREADY_ADDED); // T:[CR-2]
        pools.push(newPoolAddress); // T:[CR-3]
        isPool[newPoolAddress] = true; // T:[CR-3]

        emit NewPoolAdded(newPoolAddress); // T:[CR-4]
    }

    /// @dev Returns array of registered pool addresses
    function getPools() external view override returns (address[] memory) {
        return pools;
    }

    /// @return Returns quantity of registered pools
    function getPoolsCount() external view override returns (uint256) {
        return pools.length; // T:[CR-3]
    }

    /// @dev Adds credit accounts manager address to the registry
    /// @param newCreditManager Address on new pausableAdmin added
    function addCreditManager(address newCreditManager)
        external
        configuratorOnly // T:[CR-1]
    {
        require(
            newCreditManager != address(0),
            Errors.ZERO_ADDRESS_IS_NOT_ALLOWED
        );

        require(
            !isCreditManager[newCreditManager],
            Errors.CR_CREDIT_MANAGER_ALREADY_ADDED
        ); // T:[CR-5]
        creditManagers.push(newCreditManager); // T:[CR-6]
        isCreditManager[newCreditManager] = true; // T:[CR-6]

        emit NewCreditManagerAdded(newCreditManager); // T:[CR-7]
    }

    /// @dev Returns array of registered credit manager addresses
    function getCreditManagers()
        external
        view
        override
        returns (address[] memory)
    {
        return creditManagers;
    }

    /// @return Returns quantity of registered credit managers
    function getCreditManagersCount() external view override returns (uint256) {
        return creditManagers.length; // T:[CR-6]
    }
}