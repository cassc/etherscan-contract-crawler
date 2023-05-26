// SPDX-License-Identifier: MIT
// Copyright 2023 Proof Holdings Inc.
pragma solidity >=0.8.17;

/**
 * @notice Token information module for Evolving Pixels.
 * @author David Huber (@cxkoda)
 * @custom:reviewer Arran Schlosberg (@divergencearran)
 */
contract TokenInfoManager {
    /**
     * @notice Encodes token information in a compact way.
     * @param projectId stores the project ID of the token with an offset of +1. 0 indicates that the token has not been
     * revealed yet.
     * @param edition stores the edition of the token.
     */
    struct InternalTokenInfo {
        uint8 projectId;
        uint8 edition;
    }

    /**
     * @notice Expanded version of `InternalTokenInfo`.
     * @dev The revealed state has been extracted and projectID been shifted back to the original value.
     * @param revealed Whether the token has been revealed.
     * @param projectId The project ID of the token. Undefined if `revealed` is false.
     * @param edition The edition of the token. Undefined if `revealed` is false.
     */
    struct TokenInfo {
        bool revealed;
        uint8 projectId;
        uint8 edition;
    }

    /**
     * @notice Max numbers of tokens that this contract can store.
     * @dev This constant is intentionally very large so we never have to worry about it.
     */
    uint256 internal constant _NUM_MAX_TOKEN_INFO = (1 << 32);

    /**
     * @notice Stores token information in a compact way.
     */
    InternalTokenInfo[_NUM_MAX_TOKEN_INFO] private _infos;

    /**
     * @notice Returns the token information for the given token IDs.
     */
    function tokenInfos(uint256[] calldata tokenIds) external view returns (TokenInfo[] memory) {
        TokenInfo[] memory infos = new TokenInfo[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            infos[i] = _tokenInfo(tokenIds[i]);
        }
        return infos;
    }

    /**
     * @notice Returns the token information for the given token ID.
     * @dev This function expands the internally stored token information by checking if project ID is greater than zero
     * and subtracting the offset accordingly.
     */
    function _tokenInfo(uint256 tokenId) internal view returns (TokenInfo memory) {
        InternalTokenInfo memory info = _infos[tokenId];
        if (info.projectId == 0) {
            return TokenInfo({revealed: false, projectId: 0, edition: 0});
        }
        return TokenInfo({revealed: true, projectId: info.projectId - 1, edition: info.edition});
    }

    /**
     * @notice Sets the token information for the given token ID.
     * @dev This function stores the token information by adding an offset of +1 to the project ID.
     */
    function _setTokenInfo(uint256 tokenId, uint8 projectId, uint8 edition) internal {
        _infos[tokenId].projectId = projectId + 1;
        _infos[tokenId].edition = edition;
    }
}