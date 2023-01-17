// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "./Errors.sol";
import {IRoyaltyFeeRegistryV2} from "./interfaces/IRoyaltyFeeRegistryV2.sol";
import {IOwnable} from "./interfaces/IOwnable.sol";
import {RoyaltyFeeTypes} from "./libraries/RoyaltyFeeTypes.sol";

/**
 * @title RoyaltyFeeSetter
 * @notice Used to allow creators to set royalty information in RoyaltyFeeRegistryV2.
 */
contract RoyaltyFeeSetterV2 is Initializable, OwnableUpgradeable {
    using RoyaltyFeeTypes for RoyaltyFeeTypes.FeeInfoPart;

    // ERC721 interfaceID
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    // ERC1155 interfaceID
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    // ERC2981 interfaceID
    bytes4 public constant INTERFACE_ID_ERC2981 = 0x2a55205a;

    IRoyaltyFeeRegistryV2 public royaltyFeeRegistryV2;

    /**
     * @notice Initializer
     * @param _royaltyFeeRegistryV2 address of the royalty fee registry
     */
    function initialize(address _royaltyFeeRegistryV2) public initializer {
        __Ownable_init();

        royaltyFeeRegistryV2 = IRoyaltyFeeRegistryV2(_royaltyFeeRegistryV2);
    }

    /**
     * @notice Update royalty info for collection if admin
     * @dev Only to be called if there is no setter address
     * @param _collection address of the NFT contract
     * @param _setter address that sets the receiver
     * @param _feeInfoParts fee info parts
     */
    function updateRoyaltyInfoPartsForCollectionIfAdmin(
        address _collection,
        address _setter,
        RoyaltyFeeTypes.FeeInfoPart[] memory _feeInfoParts
    ) external {
        if (IERC165(_collection).supportsInterface(INTERFACE_ID_ERC2981)) {
            revert RoyaltyFeeSetterV2__CollectionCannotSupportERC2981();
        }
        if (msg.sender != IOwnable(_collection).admin()) {
            revert RoyaltyFeeSetterV2__NotCollectionAdmin();
        }
        _updateRoyaltyInfoPartsForCollectionIfOwnerOrAdmin(
            _collection,
            _setter,
            _feeInfoParts
        );
    }

    /**
     * @notice Update royalty info for collection if owner
     * @dev Only to be called if there is no setter address
     * @param _collection address of the NFT contract
     * @param _setter address that sets the receiver
     * @param _feeInfoParts fee info parts
     */
    function updateRoyaltyInfoPartsForCollectionIfOwner(
        address _collection,
        address _setter,
        RoyaltyFeeTypes.FeeInfoPart[] memory _feeInfoParts
    ) external {
        if (IERC165(_collection).supportsInterface(INTERFACE_ID_ERC2981)) {
            revert RoyaltyFeeSetterV2__CollectionCannotSupportERC2981();
        }
        if (msg.sender != IOwnable(_collection).owner()) {
            revert RoyaltyFeeSetterV2__NotCollectionOwner();
        }
        _updateRoyaltyInfoPartsForCollectionIfOwnerOrAdmin(
            _collection,
            _setter,
            _feeInfoParts
        );
    }

    /**
     * @notice Update royalty info for collection
     * @dev Only to be called if the msg.sender is the setter
     * @param _collection address of the NFT contract
     * @param _setter address that sets the receiver
     * @param _feeInfoParts fee info parts
     */
    function updateRoyaltyInfoPartsForCollectionIfSetter(
        address _collection,
        address _setter,
        RoyaltyFeeTypes.FeeInfoPart[] memory _feeInfoParts
    ) external {
        address currentSetter = royaltyFeeRegistryV2
            .royaltyFeeInfoPartsCollectionSetter(_collection);
        if (msg.sender != currentSetter) {
            revert RoyaltyFeeSetterV2__NotCollectionSetter();
        }
        royaltyFeeRegistryV2.updateRoyaltyInfoPartsForCollection(
            _collection,
            _setter,
            _feeInfoParts
        );
    }

    /**
     * @notice Update royalty info for collection
     * @dev Can only be called by contract owner (of this)
     * @param _collection address of the NFT contract
     * @param _setter address that sets the receiver
     * @param _feeInfoParts fee info parts
     */
    function updateRoyaltyInfoPartsForCollection(
        address _collection,
        address _setter,
        RoyaltyFeeTypes.FeeInfoPart[] memory _feeInfoParts
    ) external onlyOwner {
        royaltyFeeRegistryV2.updateRoyaltyInfoPartsForCollection(
            _collection,
            _setter,
            _feeInfoParts
        );
    }

    /**
     * @notice Update owner of royalty fee registry
     * @dev Can be used for migration of this royalty fee setter contract
     * @param _owner new owner address
     */
    function updateOwnerOfRoyaltyFeeRegistryV2(address _owner)
        external
        onlyOwner
    {
        IOwnable(address(royaltyFeeRegistryV2)).transferOwnership(_owner);
    }

    /**
     * @notice Update royalty info for collection
     * @param _royaltyFeeLimit new royalty fee limit (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyFeeLimit(uint256 _royaltyFeeLimit)
        external
        onlyOwner
    {
        royaltyFeeRegistryV2.updateRoyaltyFeeLimit(_royaltyFeeLimit);
    }

    /**
     * @notice Update information and perform checks before updating royalty fee registry
     * @param _collection address of the NFT contract
     * @param _setter address that sets the receiver
     * @param _feeInfoParts fee info parts
     */
    function _updateRoyaltyInfoPartsForCollectionIfOwnerOrAdmin(
        address _collection,
        address _setter,
        RoyaltyFeeTypes.FeeInfoPart[] memory _feeInfoParts
    ) internal {
        address currentSetter = royaltyFeeRegistryV2
            .royaltyFeeInfoPartsCollectionSetter(_collection);
        if (currentSetter != address(0)) {
            revert RoyaltyFeeSetterV2__SetterAlreadySet();
        }
        if (
            !IERC165(_collection).supportsInterface(INTERFACE_ID_ERC721) &&
            !IERC165(_collection).supportsInterface(INTERFACE_ID_ERC1155)
        ) {
            revert RoyaltyFeeSetterV2__CollectionIsNotNFT();
        }
        royaltyFeeRegistryV2.updateRoyaltyInfoPartsForCollection(
            _collection,
            _setter,
            _feeInfoParts
        );
    }
}