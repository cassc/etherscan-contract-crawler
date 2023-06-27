// SPDX-License-Identifier: Apache-2.0

//Generally all interactions should propagate downstream

pragma solidity ^0.8.18;

import "../multiasset/AbstractMultiAsset.sol";
import "./IERC6059.sol";
import "./RMRKNestable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title RMRKNestableMultiAsset
 * @author RMRK team
 * @notice Smart contract of the joined RMRK Nestable and Multi asset module.
 */
contract RMRKNestableMultiAsset is RMRKNestable, AbstractMultiAsset {
    // ------------------- ASSETS --------------

    // Mapping from token ID to approver address to approved address for assets
    // The approver is necessary so approvals are invalidated for nested children on transfer
    // WARNING: If a child NFT returns the original root owner, old permissions would be active again
    mapping(uint256 => mapping(address => address))
        private _tokenApprovalsForAssets;

    /**
     * @notice Used to verify that the caller is either the owner of the given token or approved by its owner to manage
     *  the assets on the given token.
     * @dev If the caller is not the owner of the given token or approved by its owner to manage the assets on the
     *  given token, the execution will be reverted.
     * @param tokenId ID of the token being checked
     */
    function _onlyApprovedForAssetsOrOwner(uint256 tokenId) private view {
        if (!_isApprovedForAssetsOrOwner(_msgSender(), tokenId))
            revert RMRKNotApprovedForAssetsOrOwner();
    }

    /**
     * @notice Used to verify that the caller is either the owner of the given token or approved by its owner to manage
     *  the assets on the given token.
     * @param tokenId ID of the token being checked
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
            interfaceId == type(IERC5773).interfaceId;
    }

    // ------------------------------- ASSETS ------------------------------

    // --------------------------- HANDLING ASSETS -------------------------

    /**
     * @inheritdoc IERC5773
     */
    function acceptAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) public virtual onlyApprovedForAssetsOrOwner(tokenId) {
        _acceptAsset(tokenId, index, assetId);
    }

    /**
     * @inheritdoc IERC5773
     */
    function rejectAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) public virtual onlyApprovedForAssetsOrOwner(tokenId) {
        _rejectAsset(tokenId, index, assetId);
    }

    /**
     * @inheritdoc IERC5773
     */
    function rejectAllAssets(
        uint256 tokenId,
        uint256 maxRejections
    ) public virtual onlyApprovedForAssetsOrOwner(tokenId) {
        _rejectAllAssets(tokenId, maxRejections);
    }

    /**
     * @inheritdoc IERC5773
     */
    function setPriority(
        uint256 tokenId,
        uint64[] calldata priorities
    ) public virtual onlyApprovedForAssetsOrOwner(tokenId) {
        _setPriority(tokenId, priorities);
    }

    // ----------------------- APPROVALS FOR ASSETS ------------------------

    /**
     * @inheritdoc IERC5773
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
     * @inheritdoc IERC5773
     */
    function getApprovedForAssets(
        uint256 tokenId
    ) public view virtual returns (address) {
        _requireMinted(tokenId);
        return _tokenApprovalsForAssets[tokenId][ownerOf(tokenId)];
    }

    /**
     * @notice Used to grant an approval to an address to manage assets of a given token.
     * @param to Address of the account to grant the approval to
     * @param tokenId ID of the token for which the approval is being given
     */
    function _approveForAssets(address to, uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);
        _tokenApprovalsForAssets[tokenId][owner] = to;
        emit ApprovalForAssets(owner, to, tokenId);
    }

    /**
     * @notice Used to remove approvals to manage the assets for a given token.
     * @param tokenId ID of the token for which to clear the approvals
     */
    function _cleanApprovals(uint256 tokenId) internal virtual override {
        _approveForAssets(address(0), tokenId);
    }

    ////////////////////////////////////////
    //              UTILS
    ////////////////////////////////////////

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
}