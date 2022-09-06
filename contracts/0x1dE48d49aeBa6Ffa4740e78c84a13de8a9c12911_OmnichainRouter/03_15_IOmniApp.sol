// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

interface IOmniApp {
    /**
     * @notice Function to be implemented by the Omnichain Application ("OA") utilizing Omnichain Router for receiving
     *         cross-chain messages.
     *
     * @param payload Encoded payload with a data for a target function execution.
     * @param srcOA Address of the remote Omnichain Application ("OA") that can be used for source validation.
     * @param srcChain Name of the source remote chain.
     */
    function omReceive(bytes calldata payload, address srcOA, string memory srcChain) external;
}