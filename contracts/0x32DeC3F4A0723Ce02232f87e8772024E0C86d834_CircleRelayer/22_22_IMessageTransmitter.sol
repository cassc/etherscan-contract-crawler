// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMessageTransmitter {
    /**
     * @notice Emitted when tokens are minted
     * @param _mintRecipient recipient address of minted tokens
     * @param _amount amount of minted tokens
     * @param _mintToken contract address of minted token
     */
    event MintAndWithdraw(address _mintRecipient, uint256 _amount, address _mintToken);

    /**
     * @notice Receive a message. Messages with a given nonce
     * can only be broadcast once for a (sourceDomain, destinationDomain)
     * pair. The message body of a valid message is passed to the
     * specified recipient for further processing.
     *
     * @dev Attestation format:
     * A valid attestation is the concatenated 65-byte signature(s) of exactly
     * `thresholdSignature` signatures, in increasing order of attester address.
     * ***If the attester addresses recovered from signatures are not in
     * increasing order, signature verification will fail.***
     * If incorrect number of signatures or duplicate signatures are supplied,
     * signature verification will fail.
     *
     * Message format:
     * Field Bytes Type Index
     * version 4 uint32 0
     * sourceDomain 4 uint32 4
     * destinationDomain 4 uint32 8
     * nonce 8 uint64 12
     * sender 32 bytes32 20
     * recipient 32 bytes32 52
     * messageBody dynamic bytes 84
     * @param _message Message bytes
     * @param _attestation Concatenated 65-byte signature(s) of `_message`, in increasing order
     * of the attester address recovered from signatures.
     * @return success bool, true if successful
     */
    function receiveMessage(bytes memory _message, bytes calldata _attestation) external returns (bool success);

    function attesterManager() external view returns (address);

    function availableNonces(uint32 domain) external view returns (uint64);

    function getNumEnabledAttesters() external view returns (uint256);

    function isEnabledAttester(address _attester) external view returns (bool);

    function localDomain() external view returns (uint32);

    function maxMessageBodySize() external view returns (uint256);

    function owner() external view returns (address);

    function paused() external view returns (bool);

    function pauser() external view returns (address);

    function rescuer() external view returns (address);

    function version() external view returns (uint32);

    // owner only methods
    function transferOwnership(address newOwner) external;

    function updateAttesterManager(address _newAttesterManager) external;

    // attester manager only methods
    function getEnabledAttester(uint256 _index) external view returns (address);

    function disableAttester(address _attester) external;

    function enableAttester(address _attester) external;

    function setSignatureThreshold(uint256 newSignatureThreshold) external;
}