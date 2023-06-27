// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import "../equippable/IERC6220.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../library/RMRKErrors.sol";

/**
 * @title RMRKBulkWriter
 * @author RMRK team
 * @notice Smart contract of the RMRK Bulk Writer module.
 * @dev Extra utility functions for RMRK contracts.
 */
contract RMRKBulkWriter {
    /**
     * @notice Used to provide a struct for inputing unequip data.
     * @dev Only used for input and not storage of data.
     * @return assetId ID of the asset that we are equipping into
     * @return slotPartId ID of the slot part that we are using to unequip
     */
    struct IntakeUnequip {
        uint64 assetId;
        uint64 slotPartId;
    }

    /**
     * @notice Reverts if the caller is not the owner of the token.
     * @param collection Address of the collection that this contract is managing
     * @param tokenId ID of the token we are managing
     */
    modifier onlyTokenOwner(address collection, uint256 tokenId) {
        _checkTokenOwner(collection, tokenId);
        _;
    }

    /**
     * @notice Initializes the contract.
     */
    constructor() {}

    /**
     * @notice Replaces the current equipped child in the asset and slot combination with the given one.
     * @dev The `IntakeEquip` stuct contains the following data:
     *  [
     *      tokenId,
     *      childIndex,
     *      assetId,
     *      slotPartId,
     *      childAssetId
     *  ]
     * @param collection Address of the collection that this contract is managing
     * @param data An `IntakeEquip` struct specifying the equip data
     */
    function replaceEquip(
        address collection,
        IERC6220.IntakeEquip memory data
    ) public onlyTokenOwner(collection, data.tokenId) {
        IERC6220(collection).unequip(
            data.tokenId,
            data.assetId,
            data.slotPartId
        );
        IERC6220(collection).equip(data);
    }

    /**
     * @notice Performs multiple unequip and/or equip operations.
     * @dev Unequip operations must run first.
     * @dev Unequip operations do not need to be related to the equip operations; this method does not force you to only equip the assets into the slots that were unequipped.
     * @dev `tokenId` is included as a parameter to be able to do a single check for ownership.
     * @dev Every `tokenId` in the `IntakeEquip` structs must match the `tokenId` passed as the argument.
     * @dev The `IntakeUnequip` stuct contains the following data:
     *  [
     *      assetId,
     *      slotPartId,
     *  ]
     * @dev The `IntakeEquip` stuct contains the following data:
     *  [
     *      tokenId,
     *      childIndex,
     *      assetId,
     *      slotPartId,
     *      childAssetId
     *  ]
     * @param collection Address of the collection that this contract is managing
     * @param tokenId ID of the token we are managing
     * @param unequips[] An array of `IntakeUnequip` structs specifying the slots to unequip
     * @param equips[] An array of `IntakeEquip` structs specifying the slots to equip
     */
    function bulkEquip(
        address collection,
        uint256 tokenId,
        IntakeUnequip[] memory unequips,
        IERC6220.IntakeEquip[] memory equips
    ) public onlyTokenOwner(collection, tokenId) {
        uint256 length = unequips.length;
        for (uint256 i; i < length; ) {
            IERC6220(collection).unequip(
                tokenId,
                unequips[i].assetId,
                unequips[i].slotPartId
            );
            unchecked {
                ++i;
            }
        }
        length = equips.length;
        for (uint256 i; i < length; ) {
            if (equips[i].tokenId != tokenId) {
                revert RMRKCanOnlyDoBulkOperationsWithOneTokenAtATime();
            }
            IERC6220(collection).equip(equips[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Validates that the caller is the owner of the token.
     * @dev Reverts if the caller is not the owner of the token.
     * @param collection Address of the collection that this contract is managing
     * @param tokenId ID of the token we are managing
     */
    function _checkTokenOwner(
        address collection,
        uint256 tokenId
    ) internal view {
        address tokenOwner = IERC721(collection).ownerOf(tokenId);
        if (tokenOwner != msg.sender) {
            revert RMRKCanOnlyDoBulkOperationsOnOwnedTokens();
        }
    }
}