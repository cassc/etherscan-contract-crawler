// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.18;

error RouteCallLibrary_Call_Failed_Without_Revert_Reason();

/**
 * @title A library for calling external contracts with an address appended to the calldata.
 * @author HardlyDifficult
 */
library RouteCallLibrary {
  /**
   * @notice Routes a call to the specified contract, appending the from address to the end of the calldata.
   * If the call reverts, this will revert the transaction and the original reason is bubbled up.
   * @param from The address to use as the msg sender when calling the contract.
   * @param to The contract address to call.
   * @param callData The call data to use when calling the contract, without the sender appended.
   */
  function routeCallTo(address from, address to, bytes memory callData) internal returns (bytes memory returnData) {
    // Forward the call, with the packed from address appended, to the specified contract.
    bool success;
    (success, returnData) = tryRouteCallTo(from, to, callData);

    // If the call failed, bubble up the revert reason.
    if (!success) {
      revertWithError(returnData);
    }
  }

  /**
   * @notice Routes a call to the specified contract, appending the from address to the end of the calldata.
   * This will not revert even if the external call fails.
   * @param from The address to use as the msg sender when calling the contract.
   * @param to The contract address to call.
   * @param callData The call data to use when calling the contract, without the sender appended.
   */
  function tryRouteCallTo(
    address from,
    address to,
    bytes memory callData
  ) internal returns (bool success, bytes memory returnData) {
    // Forward the call, with the packed from address appended, to the specified contract.
    // solhint-disable-next-line avoid-low-level-calls
    (success, returnData) = to.call(abi.encodePacked(callData, from));
  }

  /**
   * @notice Bubbles up the original revert reason of a low-level call failure where possible.
   * @dev Copied from OZ's `Address.sol` library, with a minor modification to the final revert scenario.
   * This should only be used when a low-level call fails.
   */
  function revertWithError(bytes memory returnData) internal pure {
    // Look for revert reason and bubble it up if present
    if (returnData.length > 0) {
      // The easiest way to bubble the revert reason is using memory via assembly
      /// @solidity memory-safe-assembly
      assembly {
        let returnData_size := mload(returnData)
        revert(add(32, returnData), returnData_size)
      }
    } else {
      revert RouteCallLibrary_Call_Failed_Without_Revert_Reason();
    }
  }

  /**
   * @notice Extracts the appended sender address from the calldata.
   * @dev This uses the last 20 bytes of the calldata, with no guarantees that an address has indeed been appended.
   * If this is used for a call that was not routed with `routeCallTo`, the address returned will be incorrect (and
   * may be address(0)).
   */
  function extractAppendedSenderAddress() internal pure returns (address sender) {
    assembly {
      // The router appends the msg.sender to the end of the calldata
      // source: https://github.com/opengsn/gsn/blob/v3.0.0-beta.3/packages/contracts/src/ERC2771Recipient.sol#L48
      sender := shr(96, calldataload(sub(calldatasize(), 20)))
    }
  }
}