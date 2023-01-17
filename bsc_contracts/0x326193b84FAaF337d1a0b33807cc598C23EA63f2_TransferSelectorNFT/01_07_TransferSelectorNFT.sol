// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {ITransferSelectorNFT} from "./interfaces/ITransferSelectorNFT.sol";

/**
 * @title TransferSelectorNFT
 * @notice It selects the NFT transfer manager based on a collection address.
 */
contract TransferSelectorNFT is
    ITransferSelectorNFT,
    Initializable,
    OwnableUpgradeable
{
    // ERC721 interfaceID
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    // ERC1155 interfaceID
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    // Address of the transfer manager contract for ERC721 tokens
    address public transferManagerERC721;

    // Address of the transfer manager contract for ERC1155 tokens
    address public transferManagerERC1155;

    // Map collection address to transfer manager address
    mapping(address => address) public transferManagerSelectorForCollection;

    event CollectionTransferManagerAdded(
        address indexed collection,
        address indexed transferManager
    );
    event CollectionTransferManagerRemoved(address indexed collection);

    /**
     * @notice Initializer
     * @param _transferManagerERC721 address of the ERC721 transfer manager
     * @param _transferManagerERC1155 address of the ERC1155 transfer manager
     */
    function initialize(
        address _transferManagerERC721,
        address _transferManagerERC1155
    ) public initializer {
        __Ownable_init();

        transferManagerERC721 = _transferManagerERC721;
        transferManagerERC1155 = _transferManagerERC1155;
    }

    /**
     * @notice Add a transfer manager for a collection
     * @param collection collection address to add specific transfer rule
     * @dev It is meant to be used for exceptions only (e.g., CryptoKitties)
     */
    function addCollectionTransferManager(
        address collection,
        address transferManager
    ) external onlyOwner {
        require(
            collection != address(0),
            "TransferSelectorNFT: Collection cannot be null address"
        );
        require(
            transferManager != address(0),
            "TransferSelectorNFT: TransferManager cannot be null address"
        );

        transferManagerSelectorForCollection[collection] = transferManager;

        emit CollectionTransferManagerAdded(collection, transferManager);
    }

    /**
     * @notice Remove a transfer manager for a collection
     * @param collection collection address to remove exception
     */
    function removeCollectionTransferManager(address collection)
        external
        onlyOwner
    {
        require(
            transferManagerSelectorForCollection[collection] != address(0),
            "TransferSelectorNFT: Collection has no transfer manager"
        );

        // Set it to the address(0)
        transferManagerSelectorForCollection[collection] = address(0);

        emit CollectionTransferManagerRemoved(collection);
    }

    /**
     * @notice Check the transfer manager for a token
     * @dev Support for ERC165 interface is checked AFTER custom implementation
     * @param collection collection address
     * @return transferManager address of transfer manager to use
     */
    function checkTransferManagerForToken(address collection)
        external
        view
        override
        returns (address transferManager)
    {
        // Assign transfer manager (if any)
        transferManager = transferManagerSelectorForCollection[collection];

        if (transferManager == address(0)) {
            if (IERC165(collection).supportsInterface(INTERFACE_ID_ERC721)) {
                transferManager = transferManagerERC721;
            } else if (
                IERC165(collection).supportsInterface(INTERFACE_ID_ERC1155)
            ) {
                transferManager = transferManagerERC1155;
            } else {
                revert(
                    "TransferSelectorNFT: No NFT transfer manager available"
                );
            }
        }

        return transferManager;
    }
}