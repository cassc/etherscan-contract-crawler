//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/// @dev abstract contract to allow batching
/// Inspired by:
///  - https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringBatchable.sol
abstract contract Batchable {
    error TransactionRevertedSilently();

    // ---- Call management ----

    /// @notice Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is only used on the same contract, so it's safe
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
        (bool success, bytes memory returndata) = address(this).delegatecall(data);
        if (!success) {
            if (returndata.length == 0) revert TransactionRevertedSilently();
            // solhint-disable-next-line no-inline-assembly
            assembly {
                revert(add(32, returndata), mload(returndata))
            }
        }
        return returndata;
    }
}