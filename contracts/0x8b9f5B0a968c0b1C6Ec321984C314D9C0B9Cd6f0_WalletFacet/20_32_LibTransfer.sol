//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";

/// @author Amit Molek
/// @dev Transfer helpers
library LibTransfer {
    /// @dev Sends `value` in wei to `recipient`
    /// Reverts on failure
    function _untrustedSendValue(address payable recipient, uint256 value)
        internal
    {
        Address.sendValue(recipient, value);
    }

    /// @dev Performs a function call
    function _untrustedCall(
        address to,
        uint256 value,
        bytes memory data
    ) internal returns (bool successful, bytes memory returnData) {
        require(
            address(this).balance >= value,
            "Transfer: insufficient balance"
        );

        (successful, returnData) = to.call{value: value}(data);
    }

    /// @dev Extracts and bubbles the revert reason if exist, otherwise reverts with a hard-coded reason.
    function _revertWithReason(bytes memory returnData) internal pure {
        if (returnData.length == 0) {
            revert("Transfer: call reverted without a reason");
        }

        // Bubble the revert reason
        assembly {
            let returnDataSize := mload(returnData)
            revert(add(32, returnData), returnDataSize)
        }
    }
}