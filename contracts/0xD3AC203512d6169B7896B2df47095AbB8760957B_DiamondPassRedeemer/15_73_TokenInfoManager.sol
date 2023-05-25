// SPDX-License-Identifier: MIT
// Copyright 2023 Proof Holdings Inc.
pragma solidity >=0.8.17;

/**
 * @notice Token information module for Diamond Exhibition.
 * @author David Huber (@cxkoda)
 * @custom:reviewer Arran Schlosberg (@divergencearran)
 */
contract TokenInfoManager {
    /**
     * @notice Encodes token information.
     * @param projectId the ID of the project associated with the token.
     * @param edition the edition of the token within the given project.
     */
    struct TokenInfo {
        uint8 projectId;
        uint16 edition;
    }

    /**
     * @notice Max numbers of tokens that this contract can store.
     * @dev This constant is intentionally very large so we never have to worry about it.
     */
    uint256 internal constant _NUM_MAX_TOKEN_INFO = (1 << 32);

    /**
     * @notice Stores token information.
     */
    TokenInfo[_NUM_MAX_TOKEN_INFO] private _infos;

    /**
     * @notice Returns the token information for the given token IDs.
     * @dev Intended for off-chain use only.
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
     */
    function _tokenInfo(uint256 tokenId) internal view returns (TokenInfo memory) {
        return _infos[tokenId];
    }

    /**
     * @notice Sets the token information for the given token ID.
     */
    function _setTokenInfo(uint256 tokenId, uint8 projectId, uint16 edition) internal {
        _infos[tokenId] = TokenInfo({projectId: projectId, edition: edition});
    }
}