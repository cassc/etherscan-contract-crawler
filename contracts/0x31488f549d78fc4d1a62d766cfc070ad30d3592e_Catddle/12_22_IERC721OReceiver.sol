// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IERC721OReceiver {
    /**
     * @dev Receive message with `payload` from `from` on `srcChainId` chain.
     *
     * LayerZero endpoint will invoke this function to deliver the message on the destination.
     * When source sending contract invoke move(), destination contract handle the MINT/UNLOCK logic here.
     *
     * Requirements:
     *
     * - `srcChainId` and source sending contract must be setted in `remotes`
     *
     *
     * @param srcChainId the source chain identifier (use the chainId defined in LayerZero rather than general EVM chainId)
     * @param from the source sending contract address from the source chain
     * @param nonce the ordered message nonce of LayerZero endpoint
     * @param payload a custom bytes payload sent by the source sending contract
     *
     * Emits a {MoveIn} event.
     */
    function lzReceive(
        uint16 srcChainId,
        bytes memory from,
        uint64 nonce,
        bytes memory payload
    ) external;
}