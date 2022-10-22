// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library RevertLib {
    function revertBytes(bytes memory data) internal {
        assembly {
            // array length is stored at offset 0, so it is accessed using `mload(result)`
            // data is stored at offset 0x20 (first 0x20 bytes are for length), so `add(result, 0x20)` returns data slot
            revert(add(data, 0x20), mload(data))
        }
    }

    function propagateError(
        bool success,
        bytes memory data,
        string memory errorMessage
    ) internal {
        // Forward error message from call/delegatecall
        if (!success) {
            if (data.length == 0) {
                revert(errorMessage);
            }

            revertBytes(data);
        }
    }
}