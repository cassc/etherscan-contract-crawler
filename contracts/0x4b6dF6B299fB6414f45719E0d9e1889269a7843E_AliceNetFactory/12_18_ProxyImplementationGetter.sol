// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

abstract contract ProxyImplementationGetter {
    function __getProxyImplementation(address _proxy) internal view returns (address implAddress) {
        bytes memory cdata = hex"0cbcae703c";
        assembly ("memory-safe") {
            let success := staticcall(gas(), _proxy, add(cdata, 0x20), mload(cdata), 0x00, 0x00)
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, returndatasize()))
            returndatacopy(ptr, 0x00, returndatasize())
            if iszero(success) {
                revert(ptr, returndatasize())
            }
            implAddress := shr(96, mload(ptr))
        }
    }
}