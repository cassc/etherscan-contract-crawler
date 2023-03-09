// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.16;

contract UpgradeableProxy {
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(address implementation) {
        assembly {
            sstore(_IMPLEMENTATION_SLOT, implementation)
        }
    }

    fallback() external payable {
        assembly {
            let addr := sload(_IMPLEMENTATION_SLOT)
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), addr, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}