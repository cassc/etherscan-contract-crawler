// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

abstract contract ProxyUpgrader {
    function __upgrade(address _proxy, address _newImpl) internal {
        bytes memory cdata = abi.encodeWithSelector(0xca11c0de, _newImpl);
        assembly {
            if iszero(call(gas(), _proxy, 0, add(cdata, 0x20), mload(cdata), 0x00, 0x00)) {
                let ptr := mload(0x40)
                mstore(0x40, add(ptr, returndatasize()))
                returndatacopy(ptr, 0x00, returndatasize())
                revert(ptr, returndatasize())
            }
        }
    }
}