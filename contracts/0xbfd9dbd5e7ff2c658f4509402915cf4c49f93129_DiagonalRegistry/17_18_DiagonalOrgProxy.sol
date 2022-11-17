// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import { IDiagonalOrgProxy } from "../interfaces/proxy/IDiagonalOrgProxy.sol";
import { IDiagonalOrgBeacon } from "../interfaces/proxy/IDiagonalOrgBeacon.sol";
import { Initializable } from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";

contract DiagonalOrgProxy is Initializable, IDiagonalOrgProxy {
    /*******************************
     * Errors *
     *******************************/

    error DiagonalOrgProxyInitializationFailed();
    error SendingEthUnsupported();

    /*******************************
     * Constants *
     *******************************/

    // EIP 1967 BEACON SLOT
    // bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1)
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /*******************************
     * Functions start *
     *******************************/

    /**
     * @notice Initilizes proxy by calling `_setBeacon`
     * @param beacon The address of the DiagonalOrgBeacon contract
     * @param data The data used in a delegate call to the implementation returned by the beacon
     */
    function initializeProxy(
        address beacon,
        address implementation,
        bytes calldata data
    ) external initializer {
        assert(_BEACON_SLOT == bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1));

        if (data.length == 0) revert DiagonalOrgProxyInitializationFailed();

        _setBeacon(beacon);

        _safeInitDelegateCall(implementation, data);
    }

    // solhint-disable-next-line no-complex-fallback
    fallback() external payable {
        address implementation = _implementation();

        // solhint-disable-next-line no-inline-assembly
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

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

    receive() external payable {
        revert SendingEthUnsupported();
    }

    function _safeInitDelegateCall(address implementation, bytes memory data) private {
        // NOTE: This method assumes "initialize()", do not return values.
        // Handling return values would involve extra checks.

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = implementation.delegatecall(data);

        if (!success) {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            }
            revert DiagonalOrgProxyInitializationFailed();
        }
    }

    function _setBeacon(address beacon) private {
        // We don't check isContract(beacon) as this is done in registry
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_BEACON_SLOT, beacon)
        }
    }

    function _beacon() private view returns (address beacon) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            beacon := sload(_BEACON_SLOT)
        }
    }

    function _implementation() private view returns (address) {
        return IDiagonalOrgBeacon(_beacon()).implementation();
    }
}