// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

abstract contract ProxyBase {
    // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1))
    bytes32 internal constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @dev Sets the implementation address of the proxy.
    /// @param newImplementation Address of the new implementation.
    function _setImplementation(address newImplementation) internal {
        require(
            Address.isContract(newImplementation),
            "ProxyBase: Cannot set a proxy implementation to a non-contract address"
        );

        bytes32 slot = IMPLEMENTATION_SLOT;

        assembly {
            sstore(slot, newImplementation)
        }
    }

    function _implementation() internal view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }
}