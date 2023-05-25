// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import {OnlySocketGateway, TransferIdExists, TransferIdDoesnotExist} from "../../errors/SocketErrors.sol";

/**
 * @title CelerStorageWrapper
 * @notice handle storageMappings used while bridging ERC20 and native on CelerBridge
 * @dev all functions ehich mutate the storage are restricted to Owner of SocketGateway
 * @author Socket dot tech.
 */
contract CelerStorageWrapper {
    /// @notice Socketgateway-address to be set in the constructor of CelerStorageWrapper
    address public immutable socketGateway;

    /// @notice mapping to store the transferId generated during bridging on Celer to message-sender
    mapping(bytes32 => address) private transferIdMapping;

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    constructor(address _socketGateway) {
        socketGateway = _socketGateway;
    }

    /**
     * @notice function to store the transferId and message-sender of a bridging activity
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in CelerBridgeData struct
     * @param transferId transferId generated during the bridging of ERC20 or native on CelerBridge
     * @param transferIdAddress message sender who is making the bridging on CelerBridge
     */
    function setAddressForTransferId(
        bytes32 transferId,
        address transferIdAddress
    ) external {
        if (msg.sender != socketGateway) {
            revert OnlySocketGateway();
        }
        if (transferIdMapping[transferId] != address(0)) {
            revert TransferIdExists();
        }
        transferIdMapping[transferId] = transferIdAddress;
    }

    /**
     * @notice function to delete the transferId when the celer bridge processes a refund.
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in CelerBridgeData struct
     * @param transferId transferId generated during the bridging of ERC20 or native on CelerBridge
     */
    function deleteTransferId(bytes32 transferId) external {
        if (msg.sender != socketGateway) {
            revert OnlySocketGateway();
        }
        if (transferIdMapping[transferId] == address(0)) {
            revert TransferIdDoesnotExist();
        }

        delete transferIdMapping[transferId];
    }

    /**
     * @notice function to lookup the address mapped to the transferId
     * @param transferId transferId generated during the bridging of ERC20 or native on CelerBridge
     * @return address of account mapped to transferId
     */
    function getAddressFromTransferId(
        bytes32 transferId
    ) external view returns (address) {
        return transferIdMapping[transferId];
    }
}