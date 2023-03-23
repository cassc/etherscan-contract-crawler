// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

/**
 * @title Celer-StorageWrapper interface
 * @notice Interface to handle storageMappings used while bridging ERC20 and native on CelerBridge
 * @dev all functions ehich mutate the storage are restricted to Owner of SocketGateway
 * @author Socket dot tech.
 */
interface ICelerStorageWrapper {
    /**
     * @notice function to store the transferId and message-sender of a bridging activity
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in CelerBridgeData struct
     * @param transferId transferId generated during the bridging of ERC20 or native on CelerBridge
     * @param transferIdAddress message sender who is making the bridging on CelerBridge
     */
    function setAddressForTransferId(
        bytes32 transferId,
        address transferIdAddress
    ) external;

    /**
     * @notice function to store the transferId and message-sender of a bridging activity
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in CelerBridgeData struct
     * @param transferId transferId generated during the bridging of ERC20 or native on CelerBridge
     */
    function deleteTransferId(bytes32 transferId) external;

    /**
     * @notice function to lookup the address mapped to the transferId
     * @param transferId transferId generated during the bridging of ERC20 or native on CelerBridge
     * @return address of account mapped to transferId
     */
    function getAddressFromTransferId(
        bytes32 transferId
    ) external view returns (address);
}