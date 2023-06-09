// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IAdapter, IRequestTypeBase} from "../interfaces/IAdapter.sol";

/**
 * @notice Interface for contracts using VRF randomness.
 * @notice Extends this and overrides particular fulfill callback function to use randomness safely.
 */
abstract contract BasicRandcastConsumerBase is IRequestTypeBase {
    address public immutable adapter;
    // Nonce on the user's side(count from 1) for generating real requestId,
    // which should be identical to the nonce on adapter's side, or it will be pointless.
    uint256 public nonce = 1;
    // Ignore fulfilling from adapter check during fee estimation.
    bool private _isEstimatingCallbackGasLimit;

    modifier calculateCallbackGasLimit() {
        _isEstimatingCallbackGasLimit = true;
        _;
        _isEstimatingCallbackGasLimit = false;
    }

    constructor(address _adapter) {
        adapter = _adapter;
    }

    // solhint-disable-next-line no-empty-blocks
    function _fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual {}
    // solhint-disable-next-line no-empty-blocks
    function _fulfillRandomWords(bytes32 requestId, uint256[] memory randomWords) internal virtual {}
    // solhint-disable-next-line no-empty-blocks
    function _fulfillShuffledArray(bytes32 requestId, uint256[] memory shuffledArray) internal virtual {}

    function _rawRequestRandomness(
        RequestType requestType,
        bytes memory params,
        uint64 subId,
        uint256 seed,
        uint16 requestConfirmations,
        uint32 callbackGasLimit,
        uint256 callbackMaxGasPrice
    ) internal returns (bytes32) {
        nonce = nonce + 1;

        IAdapter.RandomnessRequestParams memory p = IAdapter.RandomnessRequestParams(
            requestType, params, subId, seed, requestConfirmations, callbackGasLimit, callbackMaxGasPrice
        );

        return IAdapter(adapter).requestRandomness(p);
    }

    function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
        require(_isEstimatingCallbackGasLimit || msg.sender == adapter, "Only adapter can fulfill");
        _fulfillRandomness(requestId, randomness);
    }

    function rawFulfillRandomWords(bytes32 requestId, uint256[] memory randomWords) external {
        require(_isEstimatingCallbackGasLimit || msg.sender == adapter, "Only adapter can fulfill");
        _fulfillRandomWords(requestId, randomWords);
    }

    function rawFulfillShuffledArray(bytes32 requestId, uint256[] memory shuffledArray) external {
        require(_isEstimatingCallbackGasLimit || msg.sender == adapter, "Only adapter can fulfill");
        _fulfillShuffledArray(requestId, shuffledArray);
    }
}