// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ProxyModel {
    function _Proxy(address init, bytes memory data) internal virtual {
        (bool success, bytes memory reason) = init.delegatecall(data);

        if (!success) {
            assembly {
                revert(add(reason, 0x20), mload(reason))
            }
        }
    }

    function _delegate(address implementation) internal virtual {
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
}