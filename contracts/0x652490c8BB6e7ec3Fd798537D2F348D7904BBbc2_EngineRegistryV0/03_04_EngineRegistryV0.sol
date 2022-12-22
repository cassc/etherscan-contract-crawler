// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./interfaces/0.8.x/IEngineRegistryV0.sol";
import "@openzeppelin-4.7/contracts/utils/introspection/ERC165.sol";

/**
 * @title Engine Registry contract, V0.
 * @author Art Blocks Inc.
 * @notice Privileged Roles and Ownership:
 * This contract intentionally has no owners or admins, and is intended
 * to be deployed with a permissioned `deployerAddress` that may speak
 * to this registry. If in the future multiple deployer addresses are
 * needed to interact with this registry, a new registry version with
 * more complex logic should be implemented and deployed to replace this.
 */
contract EngineRegistryV0 is IEngineRegistryV0, ERC165 {
    /// configuration variable (determined at time of deployment)
    /// that determines what address may perform registration actions.
    address internal immutable deployerAddress;

    /// internal mapping for managing known list of registered contracts.
    mapping(address => bool) internal registeredContractAddresses;

    constructor() {
        // The deployer of the registry becomes the permissioned deployer for speaking to the registry.
        deployerAddress = tx.origin;
    }

    /**
     * @inheritdoc IEngineRegistryV0
     */
    function registerContract(
        address _contractAddress,
        bytes32 _coreVersion,
        bytes32 _coreType
    ) external {
        // CHECKS
        // Validate against `tx.origin` rather than `msg.sender` as it is intended that this registration be
        // performed in an automated fashion *at the time* of contract deployment for the `_contractAddress`.
        require(
            tx.origin == deployerAddress,
            "Only allowed deployer-address TX origin"
        );

        // EFFECTS
        emit ContractRegistered(_contractAddress, _coreVersion, _coreType);
        registeredContractAddresses[_contractAddress] = true;
    }

    /**
     * @inheritdoc IEngineRegistryV0
     */
    function unregisterContract(address _contractAddress) external {
        // CHECKS
        // Validate against `tx.origin` rather than `msg.sender` for consistency with the above approach,
        // as we expect in usage of this contract `msg.sender == tx.origin` to be a true assessment.
        require(
            tx.origin == deployerAddress,
            "Only allowed deployer-address TX origin"
        );
        require(
            registeredContractAddresses[_contractAddress],
            "Only unregister already registered contracts"
        );

        // EFFECTS
        emit ContractUnregistered(_contractAddress);
        registeredContractAddresses[_contractAddress] = false;
    }
}