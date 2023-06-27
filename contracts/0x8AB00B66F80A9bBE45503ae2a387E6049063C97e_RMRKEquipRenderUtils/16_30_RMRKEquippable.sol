// SPDX-License-Identifier: Apache-2.0

//Generally all interactions should propagate downstream

pragma solidity ^0.8.18;

import "../catalog/IRMRKCatalog.sol";
import "../library/RMRKLib.sol";
import "../multiasset/AbstractMultiAsset.sol";
import "../nestable/RMRKNestable.sol";
import "../security/ReentrancyGuard.sol";
import "./IERC6220.sol";

/**
 * @title RMRKEquippable
 * @author RMRK team
 * @notice Smart contract of the RMRK Equippable module.
 */
contract RMRKEquippable is
    ReentrancyGuard,
    RMRKNestable,
    AbstractMultiAsset,
    IERC6220
{
    using RMRKLib for uint64[];

    // ------------------- ASSETS --------------

    // ------------------- ASSET APPROVALS --------------

    /**
     * @notice Mapping from token ID to approver address to approved address for assets.
     * @dev The approver is necessary so approvals are invalidated for nested children on transfer.
     * @dev WARNING: If a child NFT returns the original root owner, old permissions would be active again.
     */
    mapping(uint256 => mapping(address => address))
        private _tokenApprovalsForAssets;

    // ------------------- EQUIPPABLE --------------
    /// Mapping of uint64 asset ID to corresponding catalog address.
    mapping(uint64 => address) private _catalogAddresses;
    /// Mapping of uint64 ID to asset object.
    mapping(uint64 => uint64) private _equippableGroupIds;
    /// Mapping of assetId to catalog parts applicable to this asset, both fixed and slot
    mapping(uint64 => uint64[]) private _partIds;

    /// Mapping of token ID to catalog address to slot part ID to equipment information. Used to compose an NFT.
    mapping(uint256 => mapping(address => mapping(uint64 => Equipment)))
        private _equipments;

    /// Mapping of token ID to child (nestable) address to child ID to count of equipped items. Used to check if equipped.
    mapping(uint256 => mapping(address => mapping(uint256 => uint256)))
        private _equipCountPerChild;

    /// Mapping of `equippableGroupId` to parent contract address and valid `slotId`.
    mapping(uint64 => mapping(address => uint64)) private _validParentSlots;

    /**
     * @notice Used to verify that the caller is either the owner of the given token or approved to manage the token's assets
     *  of the owner.
     * @param tokenId ID of the token that we are checking
     */
    function _onlyApprovedForAssetsOrOwner(uint256 tokenId) private view {
        if (!_isApprovedForAssetsOrOwner(_msgSender(), tokenId))
            revert RMRKNotApprovedForAssetsOrOwner();
    }

    /**
     * @notice Used to ensure that the caller is either the owner of the given token or approved to manage the token's assets
     *  of the owner.
     * @dev If that is not the case, the execution of the function will be reverted.
     * @param tokenId ID of the token that we are checking
     */
    modifier onlyApprovedForAssetsOrOwner(uint256 tokenId) {
        _onlyApprovedForAssetsOrOwner(tokenId);
        _;
    }

    // ----------------------------- CONSTRUCTOR ------------------------------

    /**
     * @notice Initializes the contract by setting a `name` and a `symbol` of the token collection.
     * @param name_ Name of the token collection
     * @param symbol_ Symbol of the token collection
     */
    constructor(
        string memory name_,
        string memory symbol_
    ) RMRKNestable(name_, symbol_) {}

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165, RMRKNestable) returns (bool) {
        return
            RMRKNestable.supportsInterface(interfaceId) ||
            interfaceId == type(IERC5773).interfaceId ||
            interfaceId == type(IERC6220).interfaceId;
    }

    // ------------------------------- ASSETS ------------------------------

    // --------------------------- ASSET HANDLERS -------------------------

    /**
     * @notice Accepts a asset at from the pending array of given token.
     * @dev Migrates the asset from the token's pending asset array to the token's active asset array.
     * @dev Active assets cannot be removed by anyone, but can be replaced by a new asset.
     * @dev Requirements:
     *
     *  - The caller must own the token or be approved to manage the token's assets
     *  - `tokenId` must exist.
     *  - `index` must be in range of the length of the pending asset array.
     * @dev Emits an {AssetAccepted} event.
     * @param tokenId ID of the token for which to accept the pending asset
     * @param index Index of the asset in the pending array to accept
     * @param assetId ID of the asset that is being accepted
     */
    function acceptAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) public virtual onlyApprovedForAssetsOrOwner(tokenId) {
        _acceptAsset(tokenId, index, assetId);
    }

    /**
     * @notice Rejects a asset from the pending array of given token.
     * @dev Removes the asset from the token's pending asset array.
     * @dev Requirements:
     *
     *  - The caller must own the token or be approved to manage the token's assets
     *  - `tokenId` must exist.
     *  - `index` must be in range of the length of the pending asset array.
     * @dev Emits a {AssetRejected} event.
     * @param tokenId ID of the token that the asset is being rejected from
     * @param index Index of the asset in the pending array to be rejected
     * @param assetId ID of the asset that is being rejected
     */
    function rejectAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) public virtual onlyApprovedForAssetsOrOwner(tokenId) {
        _rejectAsset(tokenId, index, assetId);
    }

    /**
     * @notice Rejects all assets from the pending array of a given token.
     * @dev Effecitvely deletes the pending array.
     * @dev Requirements:
     *
     *  - The caller must own the token or be approved to manage the token's assets
     *  - `tokenId` must exist.
     * @dev Emits a {AssetRejected} event with assetId = 0.
     * @param tokenId ID of the token of which to clear the pending array.
     * @param maxRejections Maximum number of expected assets to reject, used to prevent from rejecting assets which
     *  arrive just before this operation.
     */
    function rejectAllAssets(
        uint256 tokenId,
        uint256 maxRejections
    ) public virtual onlyApprovedForAssetsOrOwner(tokenId) {
        _rejectAllAssets(tokenId, maxRejections);
    }

    /**
     * @notice Sets a new priority array for a given token.
     * @dev The priority array is a non-sequential list of `uint64`s, where the lowest value is considered highest
     *  priority.
     * @dev Value `0` of a priority is a special case equivalent to unitialized.
     * @dev Requirements:
     *
     *  - The caller must own the token or be approved to manage the token's assets
     *  - `tokenId` must exist.
     *  - The length of `priorities` must be equal the length of the active assets array.
     * @dev Emits a {AssetPrioritySet} event.
     * @param tokenId ID of the token to set the priorities for
     * @param priorities An array of priority values
     */
    function setPriority(
        uint256 tokenId,
        uint64[] calldata priorities
    ) public virtual onlyApprovedForAssetsOrOwner(tokenId) {
        _setPriority(tokenId, priorities);
    }

    // --------------------------- ASSET INTERNALS -------------------------

    /**
     * @notice Used to add a asset entry.
     * @dev This internal function warrants custom access control to be implemented when used.
     * @param id ID of the asset being added
     * @param equippableGroupId ID of the equippable group being marked as equippable into the slot associated with
     *  `Parts` of the `Slot` type
     * @param catalogAddress Address of the `Catalog` associated with the asset
     * @param metadataURI The metadata URI of the asset
     * @param partIds An array of IDs of fixed and slot parts to be included in the asset
     */
    function _addAssetEntry(
        uint64 id,
        uint64 equippableGroupId,
        address catalogAddress,
        string memory metadataURI,
        uint64[] memory partIds
    ) internal virtual {
        _addAssetEntry(id, metadataURI);

        if (catalogAddress == address(0) && partIds.length != 0)
            revert RMRKCatalogRequiredForParts();

        _catalogAddresses[id] = catalogAddress;
        _equippableGroupIds[id] = equippableGroupId;
        _partIds[id] = partIds;
    }

    // ----------------------- ASSET APPROVALS ------------------------

    /**
     * @notice Used to grant approvals for specific tokens to a specified address.
     * @dev This can only be called by the owner of the token or by an account that has been granted permission to
     *  manage all of the owner's assets.
     * @param to Address of the account to receive the approval to the specified token
     * @param tokenId ID of the token for which we are granting the permission
     */
    function approveForAssets(address to, uint256 tokenId) public virtual {
        address owner = ownerOf(tokenId);
        if (to == owner) revert RMRKApprovalForAssetsToCurrentOwner();

        if (
            _msgSender() != owner &&
            !isApprovedForAllForAssets(owner, _msgSender())
        ) revert RMRKApproveForAssetsCallerIsNotOwnerNorApprovedForAll();
        _approveForAssets(to, tokenId);
    }

    /**
     * @notice Used to get the address of the user that is approved to manage the specified token from the current
     *  owner.
     * @param tokenId ID of the token we are checking
     * @return Address of the account that is approved to manage the token
     */
    function getApprovedForAssets(
        uint256 tokenId
    ) public view virtual returns (address) {
        _requireMinted(tokenId);
        return _tokenApprovalsForAssets[tokenId][ownerOf(tokenId)];
    }

    /**
     * @notice Internal function to check whether the queried user is either:
     *   1. The root owner of the token associated with `tokenId`.
     *   2. Is approved for all assets of the current owner via the `setApprovalForAllForAssets` function.
     *   3. Is granted approval for the specific tokenId for asset management via the `approveForAssets` function.
     * @param user Address of the user we are checking for permission
     * @param tokenId ID of the token to query for permission for a given `user`
     * @return A boolean value indicating whether the user is approved to manage the token or not
     */
    function _isApprovedForAssetsOrOwner(
        address user,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId);
        return (user == owner ||
            isApprovedForAllForAssets(owner, user) ||
            getApprovedForAssets(tokenId) == user);
    }

    /**
     * @notice Internal function for granting approvals for a specific token.
     * @param to Address of the account we are granting an approval to
     * @param tokenId ID of the token we are granting the approval for
     */
    function _approveForAssets(address to, uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);
        _tokenApprovalsForAssets[tokenId][owner] = to;
        emit ApprovalForAssets(owner, to, tokenId);
    }

    /**
     * @notice Used to clear the approvals on a given token.
     * @param tokenId ID of the token we are clearing the approvals of
     */
    function _cleanApprovals(uint256 tokenId) internal virtual override {
        _approveForAssets(address(0), tokenId);
    }

    // ------------------------------- EQUIPPING ------------------------------

    /**
     * @inheritdoc RMRKNestable
     */
    function _transferChild(
        uint256 tokenId,
        address to,
        uint256 destinationId,
        uint256 childIndex,
        address childAddress,
        uint256 childId,
        bool isPending,
        bytes memory data
    ) internal virtual override {
        if (!isPending) {
            if (isChildEquipped(tokenId, childAddress, childId))
                revert RMRKMustUnequipFirst();
        }
        super._transferChild(
            tokenId,
            to,
            destinationId,
            childIndex,
            childAddress,
            childId,
            isPending,
            data
        );
    }

    /**
     * @inheritdoc IERC6220
     */
    function equip(
        IntakeEquip memory data
    ) public virtual onlyApprovedOrOwner(data.tokenId) nonReentrant {
        _equip(data);
    }

    /**
     * @notice Private function used to equip a child into a token.
     * @dev If the `Slot` already has an item equipped, the execution will be reverted.
     * @dev If the child can't be used in the given `Slot`, the execution will be reverted.
     * @dev If the catalog doesn't allow this equip to happen, the execution will be reverted.
     * @dev The `IntakeEquip` stuct contains the following data:
     *  [
     *      tokenId,
     *      childIndex,
     *      assetId,
     *      slotPartId,
     *      childAssetId
     *  ]
     * @dev Emits ***ChildAssetEquipped*** event.
     * @param data An `IntakeEquip` struct specifying the equip data
     */
    function _equip(IntakeEquip memory data) internal virtual {
        address catalogAddress = _catalogAddresses[data.assetId];
        uint64 slotPartId = data.slotPartId;
        if (
            _equipments[data.tokenId][catalogAddress][slotPartId]
                .childEquippableAddress != address(0)
        ) revert RMRKSlotAlreadyUsed();

        // Check from parent's asset perspective:
        _checkAssetAcceptsSlot(data.assetId, slotPartId);

        IERC6059.Child memory child = childOf(data.tokenId, data.childIndex);

        // Check from child perspective intention to be used in part
        // We add reentrancy guard because of this call, it happens before updating state
        if (
            !IERC6220(child.contractAddress)
                .canTokenBeEquippedWithAssetIntoSlot(
                    address(this),
                    child.tokenId,
                    data.childAssetId,
                    slotPartId
                )
        ) revert RMRKTokenCannotBeEquippedWithAssetIntoSlot();

        // Check from catalog perspective
        if (
            !IRMRKCatalog(catalogAddress).checkIsEquippable(
                slotPartId,
                child.contractAddress
            )
        ) revert RMRKEquippableEquipNotAllowedByCatalog();

        _beforeEquip(data);
        Equipment memory newEquip = Equipment({
            assetId: data.assetId,
            childAssetId: data.childAssetId,
            childId: child.tokenId,
            childEquippableAddress: child.contractAddress
        });

        _equipments[data.tokenId][catalogAddress][slotPartId] = newEquip;
        _equipCountPerChild[data.tokenId][child.contractAddress][
            child.tokenId
        ] += 1;

        emit ChildAssetEquipped(
            data.tokenId,
            data.assetId,
            slotPartId,
            child.tokenId,
            child.contractAddress,
            data.childAssetId
        );
        _afterEquip(data);
    }

    /**
     * @notice Private function to check if a given asset accepts a given slot or not.
     * @dev Execution will be reverted if the `Slot` does not apply for the asset.
     * @param assetId ID of the asset
     * @param slotPartId ID of the `Slot`
     */
    function _checkAssetAcceptsSlot(
        uint64 assetId,
        uint64 slotPartId
    ) private view {
        (, bool found) = _partIds[assetId].indexOf(slotPartId);
        if (!found) revert RMRKTargetAssetCannotReceiveSlot();
    }

    /**
     * @inheritdoc IERC6220
     */
    function unequip(
        uint256 tokenId,
        uint64 assetId,
        uint64 slotPartId
    ) public virtual onlyApprovedOrOwner(tokenId) {
        _unequip(tokenId, assetId, slotPartId);
    }

    /**
     * @notice Private function used to unequip child from parent token.
     * @dev Emits ***ChildAssetUnequipped*** event.
     * @param tokenId ID of the parent from which the child is being unequipped
     * @param assetId ID of the parent's asset that contains the `Slot` into which the child is equipped
     * @param slotPartId ID of the `Slot` from which to unequip the child
     */
    function _unequip(
        uint256 tokenId,
        uint64 assetId,
        uint64 slotPartId
    ) internal virtual {
        address targetCatalogAddress = _catalogAddresses[assetId];
        Equipment memory equipment = _equipments[tokenId][targetCatalogAddress][
            slotPartId
        ];
        if (equipment.childEquippableAddress == address(0))
            revert RMRKNotEquipped();
        _beforeUnequip(tokenId, assetId, slotPartId);

        delete _equipments[tokenId][targetCatalogAddress][slotPartId];
        _equipCountPerChild[tokenId][equipment.childEquippableAddress][
            equipment.childId
        ] -= 1;

        emit ChildAssetUnequipped(
            tokenId,
            assetId,
            slotPartId,
            equipment.childId,
            equipment.childEquippableAddress,
            equipment.childAssetId
        );
        _afterUnequip(tokenId, assetId, slotPartId);
    }

    /**
     * @inheritdoc IERC6220
     */
    function isChildEquipped(
        uint256 tokenId,
        address childAddress,
        uint256 childId
    ) public view virtual returns (bool) {
        return _equipCountPerChild[tokenId][childAddress][childId] != 0;
    }

    // --------------------- ADMIN VALIDATION ---------------------

    /**
     * @notice Internal function used to declare that the assets belonging to a given `equippableGroupId` are
     *  equippable into the `Slot` associated with the `partId` of the collection at the specified `parentAddress`.
     * @dev Emits ***ValidParentEquippableGroupIdSet*** event.
     * @param equippableGroupId ID of the equippable group
     * @param parentAddress Address of the parent into which the equippable group can be equipped into
     * @param slotPartId ID of the `Slot` that the items belonging to the equippable group can be equipped into
     */
    function _setValidParentForEquippableGroup(
        uint64 equippableGroupId,
        address parentAddress,
        uint64 slotPartId
    ) internal virtual {
        if (equippableGroupId == uint64(0) || slotPartId == uint64(0))
            revert RMRKIdZeroForbidden();
        _validParentSlots[equippableGroupId][parentAddress] = slotPartId;
        emit ValidParentEquippableGroupIdSet(
            equippableGroupId,
            slotPartId,
            parentAddress
        );
    }

    /**
     * @inheritdoc IERC6220
     */
    function canTokenBeEquippedWithAssetIntoSlot(
        address parent,
        uint256 tokenId,
        uint64 assetId,
        uint64 slotId
    ) public view virtual returns (bool) {
        uint64 equippableGroupId = _equippableGroupIds[assetId];
        uint64 equippableSlot = _validParentSlots[equippableGroupId][parent];
        if (equippableSlot == slotId) {
            (, bool found) = getActiveAssets(tokenId).indexOf(assetId);
            return found;
        }
        return false;
    }

    // --------------------- Getting Extended Assets ---------------------

    /**
     * @inheritdoc IERC6220
     */
    function getAssetAndEquippableData(
        uint256 tokenId,
        uint64 assetId
    )
        public
        view
        virtual
        returns (string memory, uint64, address, uint64[] memory)
    {
        return (
            getAssetMetadata(tokenId, assetId),
            _equippableGroupIds[assetId],
            _catalogAddresses[assetId],
            _partIds[assetId]
        );
    }

    ////////////////////////////////////////
    //              UTILS
    ////////////////////////////////////////

    /**
     * @inheritdoc IERC6220
     */
    function getEquipment(
        uint256 tokenId,
        address targetCatalogAddress,
        uint64 slotPartId
    ) public view virtual returns (Equipment memory) {
        return _equipments[tokenId][targetCatalogAddress][slotPartId];
    }

    // HOOKS

    /**
     * @notice A hook to be called before a equipping a asset to the token.
     * @dev The `IntakeEquip` struct consist of the following data:
     *  [
     *      tokenId,
     *      childIndex,
     *      assetId,
     *      slotPartId,
     *      childAssetId
     *  ]
     * @param data The `IntakeEquip` struct containing data of the asset that is being equipped
     */
    function _beforeEquip(IntakeEquip memory data) internal virtual {}

    /**
     * @notice A hook to be called after equipping a asset to the token.
     * @dev The `IntakeEquip` struct consist of the following data:
     *  [
     *      tokenId,
     *      childIndex,
     *      assetId,
     *      slotPartId,
     *      childAssetId
     *  ]
     * @param data The `IntakeEquip` struct containing data of the asset that was equipped
     */
    function _afterEquip(IntakeEquip memory data) internal virtual {}

    /**
     * @notice A hook to be called before unequipping a asset from the token.
     * @param tokenId ID of the token from which the asset is being unequipped
     * @param assetId ID of the asset being unequipped
     * @param slotPartId ID of the slot from which the asset is being unequipped
     */
    function _beforeUnequip(
        uint256 tokenId,
        uint64 assetId,
        uint64 slotPartId
    ) internal virtual {}

    /**
     * @notice A hook to be called after unequipping a asset from the token.
     * @param tokenId ID of the token from which the asset was unequipped
     * @param assetId ID of the asset that was unequipped
     * @param slotPartId ID of the slot from which the asset was unequipped
     */
    function _afterUnequip(
        uint256 tokenId,
        uint64 assetId,
        uint64 slotPartId
    ) internal virtual {}
}