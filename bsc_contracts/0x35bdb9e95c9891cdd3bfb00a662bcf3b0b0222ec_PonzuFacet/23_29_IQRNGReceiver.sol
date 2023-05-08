// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IQRNGReceiver {
  /// @notice Called by the Airnode through the AirnodeRrp contract to
  /// fulfill the request
  /// @dev Note the `onlyAirnodeRrp` modifier. You should only accept RRP
  /// fulfillments from this protocol contract. Also note that only
  /// fulfillments for the requests made by this contract are accepted, and
  /// a request cannot be responded to multiple times.
  /// @param requestId Request ID
  /// @param data ABI-encoded response
  function fulfillUint256(bytes32 requestId, bytes calldata data) external;

  /// @notice Called by the Airnode through the AirnodeRrp contract to
  /// fulfill the request
  /// @param requestId Request ID
  /// @param data ABI-encoded response
  function fulfillUint256Array(bytes32 requestId, bytes calldata data) external;
}