// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IAccess.sol";
import "IRegistry.sol";

import "Initializable.sol";
import "Context.sol";

contract CoreController is
    Context,
    Initializable 
{
    IRegistry internal _registry;
    IAccess internal _access;

    constructor () {
        _disableInitializers();
    }

    modifier onlyInstanceOperator() {
        require(
            _registry.ensureSender(_msgSender(), "InstanceOperatorService"),
            "ERROR:CRC-001:NOT_INSTANCE_OPERATOR");
        _;
    }

    modifier onlyPolicyFlow(bytes32 module) {
        // Allow only from delegator
        require(
            address(this) == _getContractAddress(module),
            "ERROR:CRC-002:NOT_ON_STORAGE"
        );

        // Allow only ProductService (it delegates to PolicyFlow)
        require(
            _msgSender() == _getContractAddress("ProductService"),
            "ERROR:CRC-003:NOT_PRODUCT_SERVICE"
        );
        _;
    }

    function initialize(address registry) public initializer {
        _registry = IRegistry(registry);
        if (_getName() != "Access") { _access = IAccess(_getContractAddress("Access")); }
        
        _afterInitialize();
    }

    function _getName() internal virtual pure returns(bytes32) { return ""; }

    function _afterInitialize() internal virtual onlyInitializing {}

    function _getContractAddress(bytes32 contractName) internal view returns (address contractAddress) { 
        contractAddress = _registry.getContract(contractName);
        require(
            contractAddress != address(0),
            "ERROR:CRC-004:CONTRACT_NOT_REGISTERED"
        );
    }
}