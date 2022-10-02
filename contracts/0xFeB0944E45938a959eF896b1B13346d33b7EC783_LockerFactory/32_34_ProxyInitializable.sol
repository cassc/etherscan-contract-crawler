// SPDX-License-Identifier: MIT
// Fork of '@openzeppelin/contracts/proxy/utils/Initializable' (v4.5.0) but uses custom storage slots to prevent overlap
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";


abstract contract ProxyInitializable {
    // The slots being used
    // bytes32(uint256(keccak256("proxy.initialized")) - 1)
    bytes32 internal constant _INITIALIZED_SLOT = 0x8cb6127ba43c21689ceaee1c288f6c9afecd491ca56bed3bdc307e7583071ee0;
    // bytes32(uint256(keccak256("proxy.initializing")) - 1)
    bytes32 internal constant _INITIALIZING_SLOT = 0xc9937f61ef5027c577f359bef3857d1eb204659aca735360d97e23de2a7d4387;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _INITIALIZED_SLOT is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(
            StorageSlot.getBooleanSlot(_INITIALIZING_SLOT).value 
            ? _isConstructor() 
            : !StorageSlot.getBooleanSlot(_INITIALIZED_SLOT).value,
            "ProxyInitializable: contract is already initialized"
        );

        bool isTopLevelCall = !StorageSlot.getBooleanSlot(_INITIALIZING_SLOT).value;
        if (isTopLevelCall) {
            StorageSlot.getBooleanSlot(_INITIALIZING_SLOT).value = true;
            StorageSlot.getBooleanSlot(_INITIALIZED_SLOT).value = true;
        }

        _;

        if (isTopLevelCall) {
            StorageSlot.getBooleanSlot(_INITIALIZING_SLOT).value = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(StorageSlot.getBooleanSlot(_INITIALIZING_SLOT).value, "ProxyInitializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}