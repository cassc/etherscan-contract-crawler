// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NFTProxy {
    address public implementation;

    constructor() {
        implementation = 0xFC22BEA24f90df476E6c929dDc59a0D214b6Af32;
    }

    fallback() external payable {
        address impl = implementation;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }
}