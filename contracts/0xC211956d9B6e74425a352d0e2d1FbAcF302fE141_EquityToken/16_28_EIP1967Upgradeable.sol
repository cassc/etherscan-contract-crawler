// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeAware, ISafe} from "./SafeAware.sol";
import {IModuleMetadata} from "./interfaces/IModuleMetadata.sol";

// When the base contract (implementation) that proxies use is created,
// we use this no-op address when an address is needed to make contracts initialized but unusable
address constant IMPL_INIT_NOOP_ADDR = address(1);
ISafe constant IMPL_INIT_NOOP_SAFE = ISafe(payable(IMPL_INIT_NOOP_ADDR));

/**
 * @title EIP1967Upgradeable
 * @dev Minimal implementation of EIP-1967 allowing upgrades of itself by a Safe transaction
 * @dev Note that this contract doesn't have have an initializer as the implementation
 * address must already be set in the correct slot (in our case, the proxy does on creation)
 */
abstract contract EIP1967Upgradeable is SafeAware {
    event Upgraded(IModuleMetadata indexed implementation, string moduleId, uint256 version);

    // EIP1967_IMPL_SLOT = keccak256('eip1967.proxy.implementation') - 1
    bytes32 internal constant EIP1967_IMPL_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    address internal constant IMPL_CONTRACT_FLAG = address(0xffff);

    // As the base contract doesn't use the implementation slot,
    // set a flag in that slot so that it is possible to detect it
    constructor() {
        address implFlag = IMPL_CONTRACT_FLAG;
        assembly {
            sstore(EIP1967_IMPL_SLOT, implFlag)
        }
    }

    /**
     * @notice Upgrades the proxy to a new implementation address
     * @dev The new implementation should be a contract that implements a way to perform upgrades as well
     * otherwise the proxy will freeze on that implementation forever, since the proxy doesn't contain logic to change it.
     * It also must conform to the IModuleMetadata interface (this is somewhat of an implicit guard against bad upgrades)
     * @param _newImplementation The address of the new implementation address the proxy will use
     */
    function upgrade(IModuleMetadata _newImplementation) public onlySafe {
        assembly {
            sstore(EIP1967_IMPL_SLOT, _newImplementation)
        }

        emit Upgraded(_newImplementation, _newImplementation.moduleId(), _newImplementation.moduleVersion());
    }

    function _implementation() internal view returns (IModuleMetadata impl) {
        assembly {
            impl := sload(EIP1967_IMPL_SLOT)
        }
    }

    /**
     * @dev Checks whether the context is foreign to the implementation
     * or the proxy by checking the EIP-1967 implementation slot.
     * If we were running in proxy context, the impl address would be stored there
     * If we were running in impl conext, the IMPL_CONTRACT_FLAG would be stored there
     */
    function _isForeignContext() internal view returns (bool) {
        return address(_implementation()) == address(0);
    }

    function _isImplementationContext() internal view returns (bool) {
        return address(_implementation()) == IMPL_CONTRACT_FLAG;
    }
}