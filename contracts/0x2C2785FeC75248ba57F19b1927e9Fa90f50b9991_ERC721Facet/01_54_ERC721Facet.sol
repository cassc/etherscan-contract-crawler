// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SolidStateERC721} from "@solidstate/contracts/token/ERC721/SolidStateERC721.sol";
import {ERC721Metadata} from "@solidstate/contracts/token/ERC721/metadata/ERC721Metadata.sol";
import {IERC721Metadata} from "@solidstate/contracts/token/ERC721/metadata/IERC721Metadata.sol";
import {OwnableInternal} from "@solidstate/contracts/access/ownable/OwnableInternal.sol";
import {ERC721MetadataStorage} from "@solidstate/contracts/token/ERC721/metadata/ERC721MetadataStorage.sol";
import {AccessControlInternal} from "@solidstate/contracts/access/access_control/AccessControlInternal.sol";
import {ERC721Base} from "@solidstate/contracts/token/ERC721/base/ERC721Base.sol";
import {ERC721BaseInternal} from "@solidstate/contracts/token/ERC721/base/ERC721Base.sol";
import {IERC721} from "@solidstate/contracts/interfaces/IERC721.sol";
import {FeatureFlag} from "../base/FeatureFlag.sol";
import {TokenStorage} from "../libraries/storage/TokenStorage.sol";
import {IRenderMetadata} from "../interfaces/IRenderMetadata.sol";
import {BaseStorage} from "../base/BaseStorage.sol";
import {Base64} from "../libraries/Base64.sol";
import {MintVoucherVerifier} from "../base/MintVoucherVerifier.sol";
import {UpdatableOperatorFiltererInternal} from "./OperatorFilter/UpdatableOperatorFiltererInternal.sol";

/**
 *  ╔╗  ╔╗╔╗      ╔╗ ╔╗     ╔╗
 *  ║╚╗╔╝╠╝╚╗     ║║ ║║     ║║
 *  ╚╗║║╔╬╗╔╬═╦╦══╣║ ║║  ╔══╣╚═╦══╗
 *   ║╚╝╠╣║║║╔╬╣╔╗║║ ║║ ╔╣╔╗║╔╗║══╣
 *   ╚╗╔╣║║╚╣║║║╚╝║╚╗║╚═╝║╔╗║╚╝╠══║
 *    ╚╝╚╝╚═╩╝╚╩══╩═╝╚═══╩╝╚╩══╩══╝
 */

/**
 * @title  ERC721Facet
 * @author slvrfn
 * @notice Implementation contract of the abstract SolidStateERC721. The role of this contract is to handle all of the
 *         ERC-721 related logic, overriding some functions for use in the Relics.
 */
contract ERC721Facet is
    BaseStorage,
    IERC721,
    ERC721BaseInternal,
    SolidStateERC721,
    FeatureFlag,
    MintVoucherVerifier,
    AccessControlInternal,
    UpdatableOperatorFiltererInternal,
    OwnableInternal
{
    using TokenStorage for TokenStorage.Layout;

    /**
     * @notice Overridden uri function that conditionally provides different uris based on the state of the Relic.
     *         If the token has a specific uri, return it.
     *         If the token has a data in the expected arweave id slot, format and return it.
     *         Else, dynamically generate the rendered metadata based on the tokenId and global seed.
     * @param  tokenId - the token id to provide the uri for.
     */
    function tokenURI(uint256 tokenId) public view override(IERC721Metadata, ERC721Metadata) returns (string memory) {
        ERC721MetadataStorage.Layout storage m = ERC721MetadataStorage.layout();
        TokenStorage.Layout storage t = TokenStorage.layout();

        string memory tokenUri = m.tokenURIs[tokenId];
        // first slot of a tokens data is its arId if it exists (legendary for now)
        uint256 arId = t._tokenData(tokenId, 0);

        if (bytes(tokenUri).length != 0) {
            return tokenUri;
        } else if (arId != 0) {
            return Base64.getFormattedArId(abi.encodePacked(arId));
        } else {
            return IRenderMetadata(address(this)).renderMetadata(tokenId, abi.encode(m.baseURI, t._baseRelicUri()));
        }
    }

    /**
     * @notice Added to support abstract UpdatableOperatorFiltererInternal function requirement. This is used in the parent
     *         contract when interacting with the OperatorFilterRegistry.
     */
    function _owner() internal view override(UpdatableOperatorFiltererInternal, OwnableInternal) returns (address) {
        return OwnableInternal._owner();
    }

    /**
     * @notice Ensures the contract/token-transfer is not paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721BaseInternal, SolidStateERC721) {
        _requireFeaturesEnabled(0, PAUSED_FLAG_BIT | TOKEN_FLAG_BIT);
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @notice See {IERC721-setApprovalForAll}.
     *         In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function _setApprovalForAll(address operator, bool approved) internal override onlyAllowedOperatorApproval(operator) {
        super._setApprovalForAll(operator, approved);
    }

    /**
     * @notice See {IERC721-approve}.
     *         In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function _approve(address operator, uint256 tokenId) internal override onlyAllowedOperatorApproval(operator) {
        super._approve(operator, tokenId);
    }

    /**
     * @notice See {IERC721-transferFrom}.
     *         In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function _transferFrom(address from, address to, uint256 tokenId) internal override onlyAllowedOperator(from) {
        super._transferFrom(from, to, tokenId);
    }

    /**
     * @notice See {IERC721-safeTransferFrom}.
     *         In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function _safeTransferFrom(address from, address to, uint256 tokenId) internal override(ERC721BaseInternal) onlyAllowedOperator(from) {
        super._safeTransferFrom(from, to, tokenId);
    }

    /**
     * @notice Updates baseUri used for all relics.
     * @param  newUri - the new uri.
     */
    function setBaseUri(string calldata newUri) external onlyRole(keccak256("admin")) {
        ERC721MetadataStorage.Layout storage m = ERC721MetadataStorage.layout();
        m.baseURI = newUri;
    }

    /**
     * @notice ERC721 hook: revert if value is included in external transfer function call
     * @inheritdoc ERC721BaseInternal
     */
    function _handleTransferMessageValue(
        address from,
        address to,
        uint256 tokenId,
        uint256 value
    ) internal virtual override(ERC721BaseInternal, SolidStateERC721) {
        super._handleTransferMessageValue(from, to, tokenId, value);
    }

    /**
     * @notice ERC721 hook: revert if value is included in external approve function call
     * @inheritdoc ERC721BaseInternal
     */
    function _handleApproveMessageValue(
        address operator,
        uint256 tokenId,
        uint256 value
    ) internal virtual override(ERC721BaseInternal, SolidStateERC721) {
        super._handleApproveMessageValue(operator, tokenId, value);
    }

    /**
     * @notice Updates the base Relics uri used for looking up the Relic on Web2.
     * @param  newUri - the new uri.
     */
    function setBaseRelicUri(string calldata newUri) external onlyRole(keccak256("admin")) {
        TokenStorage.Layout storage t = TokenStorage.layout();
        t._setBaseRelicUri(newUri);
    }

    /**
     * @notice Updates arbitrary data for a list of tokens.
     * @param  ids - an array of ids that need to update their tokenData.
     * @param  locs - an array of slots to update the tokenData.
     * @param  bits - an array of values to set based on [id, loc] combo.
     */
    function setTokensData(uint256[] calldata ids, uint256[] calldata locs, uint256[] calldata bits) external onlyRole(keccak256("admin")) {
        TokenStorage.Layout storage t = TokenStorage.layout();
        uint256 qty = ids.length;
        for (uint i = 0; i < qty; ) {
            t._setTokenData(ids[i], locs[i], bits[i]);
            unchecked {
                ++i;
            }
        }
    }
}