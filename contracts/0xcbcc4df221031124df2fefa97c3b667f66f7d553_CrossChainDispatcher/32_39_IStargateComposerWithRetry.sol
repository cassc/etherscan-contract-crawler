// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

import "../../dependencies/stargate-protocol/interfaces/IStargateComposer.sol";

// Note: Extending interface instead of adding those function to avoid triggering upgrade for other contracts
// We may move functions to `IStargateComposer` on the next major upgrade
// Refs: https://github.com/autonomoussoftware/metronome-synth/issues/877
interface IStargateComposerWithRetry is IStargateComposer {
    function payloadHashes(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint256 _nonce
    ) external view returns (bytes32);

    function clearCachedSwap(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        address _receiver,
        bytes calldata _sgReceiveCallData
    ) external;
}