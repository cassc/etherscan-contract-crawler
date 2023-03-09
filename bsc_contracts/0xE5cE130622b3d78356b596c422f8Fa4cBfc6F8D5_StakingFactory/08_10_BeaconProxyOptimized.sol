// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";

/// @notice based on OpenZeppelin Contracts v4.4.1 (proxy/beacon/BeaconProxy.sol)
/// @dev removed all functions that are not used by BeaconProxy.sol to lower deployment gas costs
/// @dev Beacon is set once upon initialization and cannot be changed afterwards
/// @dev instread of using a storage slot, use an immutable variable
contract BeaconProxyOptimized {
    address immutable beacon;

    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor() {
        beacon = msg.sender;
        require(isContract(beacon), "ERC1967: new beacon is not a contract");
        require(isContract(IBeacon(beacon).implementation()), "ERC1967: beacon implementation is not a contract");
    }

    /**
     * @dev taken from @openzeppelin/contracts/utils/Address.sol
     */
    function isContract(address account) private view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) private {
        assembly {
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
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external virtual {
        _delegate(IBeacon(beacon).implementation());
    }
}