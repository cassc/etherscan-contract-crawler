// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../../libraries/LibDiamond.sol";
import "../../libraries/LibSwapper.sol";

contract RangoAccessManagerFacet {

    struct whitelistRequest {
        address contractAddress;
        bytes4[] methodIds;
    }

    /// @notice Notifies that a new contract is whitelisted
    /// @param _factory The address of the contract
    event ContractWhitelisted(address _factory);

    /// @notice Notifies that a new contract is whitelisted
    /// @param contractAddress The address of the contract
    /// @param methods The method signatures that are whitelisted for a contractAddress
    event ContractAndMethodsWhitelisted(address contractAddress, bytes4[] methods);

    /// @notice Notifies that a new contract is blacklisted
    /// @param _factory The address of the contract
    event ContractBlacklisted(address _factory);

    /// @notice Adds a contract & its' methods to the whitelisted DEXes that can be called
    /// @param req The array containing address of the DEX & its' methods
    function addWhitelistContract(whitelistRequest[] calldata req) public {
        LibDiamond.enforceIsContractOwner();

        for (uint i = 0; i < req.length; i++) {
            LibSwapper.addMethodWhitelists(req[i].contractAddress, req[i].methodIds);
            emit ContractAndMethodsWhitelisted(req[i].contractAddress, req[i].methodIds);
            emit ContractWhitelisted(req[i].contractAddress);
        }
    }

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