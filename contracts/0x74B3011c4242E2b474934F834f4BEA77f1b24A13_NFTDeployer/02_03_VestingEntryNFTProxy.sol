// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/proxy/Proxy.sol";

contract VestingEntryNFTProxy is Proxy {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(address _logic) Proxy() {
        assert(
            _IMPLEMENTATION_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
        );
        _setImplementation(_logic);
    }

    /**
     * @dev Returns the address of the implementation.
     */
    function _implementation() internal view override returns (address implementation) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        assembly {
            implementation := sload(slot)
        }
    }

    /**
     * @dev Stores a new address in the implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(newImplementation.code.length > 0, "Specified implementation is not a contract");
        
        bytes32 slot = _IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, newImplementation)
        }
    }
}