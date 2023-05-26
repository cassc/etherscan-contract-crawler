// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Proxy} from "../vault/Proxy.sol";
import {BaseVault} from "../vault/BaseVault.sol";
import {Owned} from "./Owned.sol";

contract Factory is Owned {

    // deployed instance of the base vault.
    address private baseVaultImpl;

    // Emitted for every new deployment of a proxy vault contract.
    event NewVaultDeployed(address indexed newProxy, address indexed owner, address[] modules, bytes[] initData);

    /**
     * @param _baseVaultImpl - deployed instance of the implementation base vault.
     */
    constructor(address _baseVaultImpl) {
        require(
            _baseVaultImpl != address(0),
            "F: Invalid address"
        );
        baseVaultImpl = _baseVaultImpl;
    }

    /**
     * Function to be executed by Kresus deployer to deploy a new instance of {Proxy}.
     * @param _owner - address of the owner of base vault contract.
     * @param _modules - Modules to be authorized to make changes to the state of vault contract.
     */
    function deployVault(
        address _owner,
        address[] calldata _modules,
        bytes[] calldata _initData
    ) 
        external
        onlyOwner()
    {
        address payable newProxy = payable(new Proxy(baseVaultImpl));
        BaseVault(newProxy).init(_owner, _modules, _initData);
        emit NewVaultDeployed(newProxy, _owner, _modules, _initData);
    }

    /**
     * Function to get current base vault implementation contract address.
     */
    function getBaseVaultImpl() external view returns(address) {
        return baseVaultImpl;
    }
}