// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

contract BloctoAccountProxy {
    /// @notice This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1,from: openzeppelin/contracts/utils/ERC1967Upgrade.sol
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @notice constructor for setting the implementation address
    /// @param implementation the initial implementation(logic) addresses, must not be zero!
    constructor(address implementation) {
        assembly {
            sstore(_IMPLEMENTATION_SLOT, implementation)
        }
    }

    /// @notice Fallback function that delegates calls to the address
    /// @dev update from "@openzeppelin/contracts/proxy/Proxy.sol"
    fallback() external payable virtual {
        assembly {
            let implementation := sload(_IMPLEMENTATION_SLOT)
            // if eq(implementation, 0) { implementation := 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9 }
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}