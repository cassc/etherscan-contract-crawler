// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../common/Errors.sol";
import "../../../../access/roles/AccessControlInternal.sol";
import "../../extensions/mintable/IERC721MintableExtension.sol";
import "../../../common/metadata/TokenMetadataAdminInternal.sol";
import "../../../ERC721/extensions/supply/ERC721SupplyStorage.sol";
import "./IERC721MintableRoleBased.sol";

/**
 * @title ERC721 - Mint as role
 * @notice Allow minting for senders with MINTER_ROLE to mint new tokens (supports ERC721A).
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:required-dependencies IERC721MintableExtension
 * @custom:provides-interfaces IERC721MintableRoleBased
 */
contract ERC721MintableRoleBased is IERC721MintableRoleBased, AccessControlInternal, TokenMetadataAdminInternal {
    using ERC721SupplyStorage for ERC721SupplyStorage.Layout;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @inheritdoc IERC721MintableRoleBased
     */
    function mintByRole(address to, uint256 amount) public virtual onlyRole(MINTER_ROLE) {
        IERC721MintableExtension(address(this)).mintByFacet(to, amount);
    }

    /**
     * @inheritdoc IERC721MintableRoleBased
     */
    function mintByRole(address[] calldata tos, uint256[] calldata amounts) public virtual onlyRole(MINTER_ROLE) {
        IERC721MintableExtension(address(this)).mintByFacet(tos, amounts);
    }

    /**
     * @inheritdoc IERC721MintableRoleBased
     */
    function mintByRole(
        address to,
        uint256 amount,
        string[] calldata tokenURIs
    ) public virtual onlyRole(MINTER_ROLE) {
        uint256 nextTokenId = ERC721SupplyStorage.layout().currentIndex;

        IERC721MintableExtension(address(this)).mintByFacet(to, amount);

        for (uint256 i = 0; i < amount; i++) {
            _setURI(nextTokenId + i, tokenURIs[i]);
        }
    }
}