// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

error ErrorHandler__ExecutionFailed();

library ErrorHandler {
    function handleRevertIfNotSuccess(bool ok_, bytes memory revertData_) internal pure {
        if (!ok_)
            if (revertData_.length != 0)
                assembly {
                    revert(
                        // Start of revert data bytes. The 0x20 offset is always the same.
                        add(revertData_, 0x20),
                        // Length of revert data.
                        mload(revertData_)
                    )
                }
            else revert ErrorHandler__ExecutionFailed();
    }
}