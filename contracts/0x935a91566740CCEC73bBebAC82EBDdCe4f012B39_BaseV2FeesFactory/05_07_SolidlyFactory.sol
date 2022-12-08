// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;
import "./SolidlyImplementation.sol";
import "./SolidlyChildProxy.sol";

contract SolidlyFactory is SolidlyImplementation {
    bytes32 constant CHILD_SUBIMPLEMENTATION_SLOT =
        0xa7461aa7cde97eb2572f8234e341359c6baae47e1feeb3c235edffe5f0fc089d; // keccak256('CHILD_SUBIMPLEMENTATION') - 1
    bytes32 constant CHILD_INTERFACE_SLOT =
        0x23762bb6469fe7a7bd6609262f442817ed09ca1f07add24ef069610d59c90649; // keccak256('CHILD_INTERFACE') - 1
    bytes32 constant SUBIMPLEMENTATION_SLOT =
        0xa1056f3ed783ff191ada02861fcb19d9ae3a8f50b739813a127951ef5290458d; // keccak256('SUBIMPLEMENTATION') - 1
    bytes32 constant INTERFACE_SLOT =
        0x4a9bf2931aa5eae439c602abae4bd662e7919244decac463e2e35fc862c5fb98; // keccak256('INTERFACE') - 1

    address public interfaceSourceAddress;

    function _deployChildProxy() internal returns (address) {
        address addr = address(new SolidlyChildProxy());

        return addr;
    }

    function _deployChildProxyWithSalt(bytes32 salt)
        internal
        returns (address)
    {
        address addr = address(new SolidlyChildProxy{salt: salt}());

        return addr;
    }

    function updateChildSubImplementationAddress(
        address _childSubImplementationAddress
    ) external onlyGovernance {
        assembly {
            sstore(CHILD_SUBIMPLEMENTATION_SLOT, _childSubImplementationAddress)
        }
    }

    function updateChildInterfaceAddress(address _childInterfaceAddress)
        external
        onlyGovernance
    {
        assembly {
            sstore(CHILD_INTERFACE_SLOT, _childInterfaceAddress)
        }
    }

    function childSubImplementationAddress()
        external
        view
        returns (address _childSubImplementation)
    {
        assembly {
            _childSubImplementation := sload(CHILD_SUBIMPLEMENTATION_SLOT)
        }
    }

    function childInterfaceAddress()
        external
        view
        returns (address _childInterface)
    {
        assembly {
            _childInterface := sload(CHILD_INTERFACE_SLOT)
        }
    }
}