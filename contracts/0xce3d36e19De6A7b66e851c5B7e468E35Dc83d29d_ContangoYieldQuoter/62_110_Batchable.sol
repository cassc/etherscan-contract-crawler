//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/// Inspired by: https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringBatchable.sol
abstract contract Batchable {
    error TransactionRevertedSilently();

    /// @notice Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    /// @return results An array with the outputs for each call.
    function batch(bytes[] calldata calls) external payable returns (bytes[] memory results) {
        results = new bytes[](calls.length);
        for (uint256 i; i < calls.length;) {
            results[i] = _delegatecall(calls[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @dev modified from https://ethereum.stackexchange.com/questions/109457/how-to-bubble-up-a-custom-error-when-using-delegatecall
    function _delegatecall(bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = address(this).delegatecall(data);
        if (!success) {
            if (returnData.length == 0) revert TransactionRevertedSilently();
            // solhint-disable-next-line no-inline-assembly
            assembly {
                revert(add(32, returnData), mload(returnData))
            }
        }
        return returnData;
    }
}