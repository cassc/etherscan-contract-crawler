// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Bubbles up errors from delegatecall
library Call {
    function _delegate(address to, bytes memory data) internal {
        (bool success, bytes memory result) = to.delegatecall(data);

        if (!success) {
            if (result.length < 68) revert();
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }
    }

    function _call(address to, bytes memory data) internal {
        (bool success, bytes memory result) = to.call(data);

        if (!success) {
            if (result.length < 68) revert('call failed');
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }
    }
}