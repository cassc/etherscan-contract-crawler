// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAccessControlChecker {
    /**
     * @dev Return whether user has access right of digital content
     *      This function is called by VWBLGateway contract
     * @param user The address of decryption key requester or decryption key sender to VWBL Network
     * @param documentId The Identifier of digital content and decryption key
     * @return True if user has access rights of digital content
     */
    function checkAccessControl(address user, bytes32 documentId) external view returns (bool);

    /**
     * @dev Return owner address of document id
     * @param documentId The Identifier of digital content and decryption key
     * @return owner address
     */
    function getOwnerAddress(bytes32 documentId) external view returns (address);
}