// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {INounletRegistry as IRegistry} from "../interfaces/INounletRegistry.sol";
import {INounletSupply as ISupply} from "../interfaces/INounletSupply.sol";

/// @title NounletSupply
/// @author Tessera
/// @notice Target contract for minting and burning fractions
contract NounletSupply is ISupply {
    /// @notice Address of NounletRegistry contract
    address public immutable registry;

    /// @dev Initializes NounletRegistry contract
    constructor(address _registry) {
        registry = _registry;
    }

    /// @notice Batch burns multiple fractions
    /// @param _from Source address
    /// @param _ids Token IDs to burn
    function batchBurn(address _from, uint256[] calldata _ids) external {
        IRegistry(registry).batchBurn(_from, _ids);
    }

    /// @notice Mints fractional tokens
    /// @param _to Target address
    /// @param _id ID of the token
    function mint(address _to, uint256 _id) external {
        IRegistry(registry).mint(_to, _id);
    }
}