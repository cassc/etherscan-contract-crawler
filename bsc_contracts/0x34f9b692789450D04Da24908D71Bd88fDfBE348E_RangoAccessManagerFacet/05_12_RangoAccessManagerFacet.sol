// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../../libraries/LibDiamond.sol";
import "../../libraries/LibSwapper.sol";

contract RangoAccessManagerFacet {
    /// Events ///

    /// @notice Notifies that a new contract is whitelisted
    /// @param _factory The address of the contract
    event ContractWhitelisted(address _factory);

    /// @notice Notifies that a new contract is blacklisted
    /// @param _factory The address of the contract
    event ContractBlacklisted(address _factory);

    /// @notice Adds a contract to the whitelisted DEXes that can be called
    /// @param _factory The address of the DEX
    function addWhitelistContract(address _factory) public {
        LibDiamond.enforceIsContractOwner();
        LibSwapper.addWhitelist(_factory);

        emit ContractWhitelisted(_factory);
    }

    /// @notice Adds a list of contracts to the whitelisted DEXes that can be called
    /// @param _factories The addresses of the DEXes
    function addWhitelists(address[] calldata _factories) external {
        LibDiamond.enforceIsContractOwner();

        for (uint i = 0; i < _factories.length; i++)
            addWhitelistContract(_factories[i]);
    }

    /// @notice Removes a contract from the whitelisted DEXes
    /// @param _factory The address of the DEX or dApp
    function removeWhitelistContract(address _factory) external {
        LibDiamond.enforceIsContractOwner();
        
        LibSwapper.removeWhitelist(_factory);

        emit ContractBlacklisted(_factory);
    }
}