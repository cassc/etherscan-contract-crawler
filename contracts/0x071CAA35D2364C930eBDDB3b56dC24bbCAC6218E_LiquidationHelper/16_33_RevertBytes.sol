// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.6 <=0.9.0;

library RevertBytes {
    function revertBytes(bytes memory _errMsg, string memory _customErr) internal pure {
        if (_errMsg.length > 0) {
            assembly { // solhint-disable-line no-inline-assembly
                revert(add(32, _errMsg), mload(_errMsg))
            }
        }

        revert(_customErr);
    }
}