// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

import "../../libraries/LibDiamond.sol";
import "../../libraries/LibSwapper.sol";

contract RangoAccessManagerFacet {

    struct whitelistRequest {
        address contractAddress;
        bytes4[] methodIds;
    }

    /// @notice Notifies that a new contract is whitelisted
    /// @param _address The address of the contract
    event ContractWhitelisted(address _address);

    /// @notice Notifies that a new contract is whitelisted
    /// @param contractAddress The address of the contract
    /// @param methods The method signatures that are whitelisted for a contractAddress
    event ContractAndMethodsWhitelisted(address contractAddress, bytes4[] methods);

    /// @notice Notifies that a new contract is blacklisted
    /// @param _address The address of the contract
    event ContractBlacklisted(address _address);

    /// @notice Notifies that a contract is blacklisted and the given methods are removed
    /// @param contractAddress The address of the contract
    /// @param methods The method signatures that are blacklisted for the given contractAddress
    event ContractAndMethodsBlacklisted(address contractAddress, bytes4[] methods);


    /// @notice Adds a contract & its' methods to the whitelisted addresses that can be called. The contract is usually a dex.
    /// @param req The array containing address of the contract & its' methods
    function addWhitelistContract(whitelistRequest[] calldata req) public {
        LibDiamond.enforceIsContractOwner();

        for (uint i = 0; i < req.length; i++) {
            LibSwapper.addMethodWhitelists(req[i].contractAddress, req[i].methodIds);
            emit ContractAndMethodsWhitelisted(req[i].contractAddress, req[i].methodIds);
            emit ContractWhitelisted(req[i].contractAddress);
        }
    }

    /// @notice Adds a contract to the whitelisted addresses that can be called
    /// @param _address The address of the contract to be whitelisted
    function addWhitelistContract(address _address) public {
        LibDiamond.enforceIsContractOwner();
        LibSwapper.addWhitelist(_address);
        emit ContractWhitelisted(_address);
    }

    /// @notice Adds a list of contracts to the whitelisted conracts that can be called
    /// @param _addresses The addresses of the contracts to be whitelisted
    function addWhitelists(address[] calldata _addresses) external {
        LibDiamond.enforceIsContractOwner();
        for (uint i = 0; i < _addresses.length; i++)
            addWhitelistContract(_addresses[i]);
    }

    /// @notice Removes a contract from the whitelisted addresses
    /// @param _address The address of the contract to be removed from whitelist
    function removeWhitelistContract(address _address) external {
        LibDiamond.enforceIsContractOwner();
        LibSwapper.removeWhitelist(_address);
        emit ContractBlacklisted(_address);
    }

    /// @notice Removes a contract and given method ids
    /// @param contractAddress The address of the contract
    /// @param methodIds The methods to be removed alongside the given contract
    function removeContractAndMethodIdsFromWhitelist(address contractAddress, bytes4[] calldata methodIds) external {
        LibDiamond.enforceIsContractOwner();
        LibSwapper.removeWhitelist(contractAddress);
        emit ContractBlacklisted(contractAddress);
        for (uint i = 0; i < methodIds.length; i++) {
            LibSwapper.removeMethodWhitelist(contractAddress, methodIds[i]);
        }
        if (methodIds.length > 0) {
            emit ContractAndMethodsBlacklisted(contractAddress, methodIds);
        }
    }
}