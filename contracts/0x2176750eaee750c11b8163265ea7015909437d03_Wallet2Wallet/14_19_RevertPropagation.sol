// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;


library RevertPropagation {
    function _require(bool _success, bytes memory _reason) internal pure {
        if (_success) {
            return;
        }
        assembly {
            revert(add(_reason, 32), mload(_reason))
        }
    }
}