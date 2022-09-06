// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {ITransfer} from "./interfaces/ITransfer.sol";
import {ITransferManager} from "./interfaces/ITransferManager.sol";

/**
 * @title TransferManager
 * @notice It selects the NFT transfer based on a collection address.
 */
contract TransferManager is ITransferManager, Ownable {
    // ERC721 interfaceID
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    // ERC1155 interfaceID
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    // Address of the transfer contract for ERC721 tokens
    address public immutable TRANSFER_ERC721;

    // Address of the transfer contract for ERC1155 tokens
    address public immutable TRANSFER_ERC1155;

    // Map collection address to transfer address
    mapping(address => address) public transfers;

    event CollectionTransferAdded(address indexed collection, address indexed transfer);
    event CollectionTransferRemoved(address indexed collection);

    /**
     * @notice Constructor
     * @param _transferERC721 address of the ERC721 transfer
     * @param _transferERC1155 address of the ERC1155 transfer
     */
    constructor(address _transferERC721, address _transferERC1155) {
        TRANSFER_ERC721 = _transferERC721;
        TRANSFER_ERC1155 = _transferERC1155;
    }

    /**
     * @notice Add a transfer   for a collection
     * @param collection collection address to add specific transfer rule
     * @dev It is meant to be used for exceptions only (e.g., CryptoKitties)
     */
    function addCollectionTransfer(address collection, address transfer) external onlyOwner {
        require(collection != address(0), "Owner: collection cannot be null address");
        require(transfer != address(0), "Owner: transfer cannot be null address");
        transfers[collection] = transfer;

        emit CollectionTransferAdded(collection, transfer);
    }

    /**
     * @notice Remove a transfer   for a collection
     * @param collection collection address to remove exception
     */
    function removeCollectionTransfer(address collection) external onlyOwner {
        require(transfers[collection] != address(0), "Owner: collection has no transfer");

        // Set it to the address(0)
        transfers[collection] = address(0);

        emit CollectionTransferRemoved(collection);
    }

    /**
     * @notice Check the transfer for a token
     * @param collection collection address
     * @dev Support for ERC165 interface is checked AFTER custom implementation
     */
    function checkTransferForToken(address collection) external view override returns (address transfer) {
        // Assign transfer   (if any)
        transfer = transfers[collection];

        if (transfer == address(0)) {
            if (IERC165(collection).supportsInterface(INTERFACE_ID_ERC721)) {
                transfer = TRANSFER_ERC721;
            } else if (IERC165(collection).supportsInterface(INTERFACE_ID_ERC1155)) {
                transfer = TRANSFER_ERC1155;
            }
        }
    }
}