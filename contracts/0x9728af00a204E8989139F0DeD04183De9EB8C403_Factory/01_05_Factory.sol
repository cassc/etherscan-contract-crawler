// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Proxy} from "./vault/Proxy.sol";
import {BaseVault} from "./vault/BaseVault.sol";

contract Factory {

    // Kresus deployer of every vault contracts.
    address deployer;

    // deployed instance of the base vault.
    address baseVaultImpl;

    // Emitted for every new deployment of a proxy vault contract.
    event NewVaultDeployed(address payable newProxy, address owner);

    /**
     * @param _deployer - address of the deployer of new vaults.
     * @param _baseVaultImpl - deployed instance of the implementation base vault.
     */
    constructor(address _deployer, address _baseVaultImpl) {
        deployer = _deployer;
        baseVaultImpl = _baseVaultImpl;
    }

    /**
     * Function to be executed by Kresus deployer to deploy a new instance of {Proxy}.
     * @param _owner - address of the owner of base vault contract.
     * @param _modules - Modules to be authorized to make changes to the state of vault contract.
     */
    function deployVault(
        address _owner,
        bytes32[] calldata _initData,
        address[] calldata _modules
    ) external {
        require(msg.sender == deployer, "F: Caller not allowed to deploy");
        address payable newProxy = payable(new Proxy(baseVaultImpl));
        BaseVault(newProxy).init(_owner, _initData, _modules);
        emit NewVaultDeployed(newProxy, _owner);
    }

    /**
     * Function to be executed by kresus deployer to change the deployer address.
     * @param _newDeployer address of the new kresus deployer.
     */
    function changeDeployer(address _newDeployer) external {
        require(msg.sender == deployer, "F: Caller not allowed to change deployer");
        deployer = _newDeployer;
    }

    /**
     * Function to get current deployer of kresus vaults.
     */
    function getDeployer() external view returns(address) {
        return deployer;
    }

    /**
     * Function to get current base vault implementation contract address.
     */
    function getBaseVaultImpl() external view returns(address) {
        return baseVaultImpl;
    }
}