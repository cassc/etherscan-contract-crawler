// SPDX-License-Identifier: MIT
// Copyright 2023 Proof Holdings Inc.
pragma solidity >=0.8.0 <0.9.0;

import {SellableERC721ACommon} from "proof/sellers/sellable/SellableERC721ACommon.sol";

/**
 * @notice Library for encoding and decoding purchase data for the Diamond Exhibition sellers.
 */
library PurchaseByProjectIDLib {
    function encodePurchaseData(uint128[] memory ids) internal pure returns (bytes memory) {
        return abi.encode(ids);
    }

    function decodePurchaseData(bytes memory data) internal pure returns (uint128[] memory) {
        return abi.decode(data, (uint128[]));
    }
}

/**
 * @notice Token information module for SellableERC721ACommonByProjectID.
 * @dev Separated for testability.
 * @author David Huber (@cxkoda)
 * @custom:reviewer Arran Schlosberg (@divergencearran)
 * @custom:reviewer Josh Laird (@jbmlaird)
 */
contract TokenInfoManager {
    /**
     * @notice Encodes token information.
     * @param projectId the ID of the project associated with the token.
     * @param edition the edition of the token within the given project.
     * @param extra extra information.
     */
    struct TokenInfo {
        uint128 projectId;
        uint64 edition;
        bytes8 extra;
    }

    /**
     * @notice Stores token information.
     */
    mapping(uint256 => TokenInfo) private _infos;

    /**
     * @notice Returns the token information for the given token IDs.
     * @dev Intended for off-chain use only.
     */
    function tokenInfos(uint256[] calldata tokenIds) external view returns (TokenInfo[] memory) {
        TokenInfo[] memory infos = new TokenInfo[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            infos[i] = tokenInfo(tokenIds[i]);
        }
        return infos;
    }

    /**
     * @notice Returns the token information for the given token ID.
     */
    function tokenInfo(uint256 tokenId) public view returns (TokenInfo memory) {
        return _infos[tokenId];
    }

    /**
     * @notice Sets the token information for the given token ID.
     */
    function _setTokenInfo(uint256 tokenId, TokenInfo memory info) internal {
        _infos[tokenId] = info;
    }
}

/**
 * @notice A sellable ERC721 contract that assigns a project ID to each token.
 * @author David Huber (@cxkoda)
 * @custom:reviewer Arran Schlosberg (@divergencearran)
 * @custom:reviewer Josh Laird (@jbmlaird)
 */
abstract contract SellableERC721ACommonByProjectID is SellableERC721ACommon, TokenInfoManager {
    // =========================================================================
    //                          Storage
    // =================================================================================================================

    /**
     * @notice The number of tokens minted per project.
     */
    mapping(uint128 => uint64) private _numPurchasedPerProject;

    /**
     * @inheritdoc SellableERC721ACommon
     * @dev Mints tokens with given project IDs encoded in the purchase data.
     */
    function _handleSale(address to, uint64 num, bytes calldata data) internal virtual override {
        uint128[] memory projectIds = PurchaseByProjectIDLib.decodePurchaseData(data);
        assert(projectIds.length == num);

        uint256 tokenId = _nextTokenId();
        for (uint256 i = 0; i < num; ++i) {
            // effects
            uint128 projectId = projectIds[i];
            uint64 edition = _numPurchasedPerProject[projectId]++;
            _setTokenInfo(tokenId, TokenInfo({projectId: projectId, edition: edition, extra: bytes8(0)}));

            // interactions
            _handleProjectMinted(tokenId, projectId, edition);

            tokenId++;
        }

        super._handleSale(to, num, data);
    }

    /**
     * @notice Hook called when a token with a given project ID is minted.
     */
    function _handleProjectMinted(uint256 tokenId, uint128 projectId, uint64 edition) internal virtual {}

    /**
     * @notice Returns the number of tokens minted for a given project.
     */
    function numPurchasedPerProject(uint128 projectId) public view returns (uint64) {
        return _numPurchasedPerProject[projectId];
    }
}