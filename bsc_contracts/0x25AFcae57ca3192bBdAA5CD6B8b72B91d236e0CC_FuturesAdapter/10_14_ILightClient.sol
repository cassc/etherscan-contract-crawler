// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ILightClient {
    /**
     * Decode and verify event information. Use require to fail the transaction
     * if any of the information is invalid.
     *
     * @param _blockchainId The blockchain that emitted the event. This could be
     *    used to determine which sets of signing keys are valid.
     * @param _eventSig The event function selector. This will be for a Start event,
     *    a Segment event, or a Root event. Not all implementations will need to
     *    use this value. Others may need this to allow then to find the event in a
     *    transaction receipt.
     * @param _payload The abi.encodePacked of the blockchain id, the Crosschain
     *    Control contract's address, the event function selector, and the event data.
     * @param _signature Signatures or proof information that an implementation can
     *    use to check that _signedEventInfo is valid.
     */
    function decodeAndVerifyEvent(
        uint256 _blockchainId,
        bytes32 _eventSig,
        bytes calldata _payload,
        bytes calldata _signature,
        address _relayer
    ) external view;
}