// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./IFragmentMiniGame.sol";
import "./FragmentMiniGameStorage.sol";

library FragmentMiniGameUtils {
    /// @dev Make sure that the given fragment group can provide the token at the desired token index.
    function canProvideToken(
        FragmentMiniGameStorage.FragmentGroup storage fg,
        bytes16 groupId,
        uint128 desiredTokenIndex,
        uint128 necessaryTokenCount
    ) internal view {
        (, uint128 totalSupply) = deconstructFragmentSupply(fg.supply[desiredTokenIndex]);

        // We're checking a case where the expected token desiredTokenIndex is not supported by the fragment group.
        if (fg.size <= desiredTokenIndex) revert IFragmentMiniGame.UnsupportedTokenIndex(groupId, desiredTokenIndex);
        if (totalSupply < necessaryTokenCount)
            revert IFragmentMiniGame.ImpossibleExpectedSupply(
                toFragmentTokenId(groupId, desiredTokenIndex),
                necessaryTokenCount
            );
    }

    function toGroupId(string memory group) internal pure returns (bytes16) {
        return bytes16(keccak256(bytes(group)));
    }

    function toFragmentTokenId(bytes16 groupId, uint128 tokenIndex) internal pure returns (uint256 tokenId) {
        return _constructTokenId(groupId, tokenIndex);
    }

    /// @dev Object groups will always use the index `0`
    function toObjectTokenId(bytes16 groupId) internal pure returns (uint256 tokenId) {
        return _constructTokenId(groupId, 0);
    }

    function toFragmentSupply(uint128 supplyLeft, uint128 totalSupply) internal pure returns (bytes32) {
        return bytes32((uint256(supplyLeft) << 128) + uint256(totalSupply));
    }

    function deconstructFragmentSupply(bytes32 fragmentSupply)
        internal
        pure
        returns (uint128 supplyLeft, uint128 totalSupply)
    {
        supplyLeft = uint128(uint256(fragmentSupply) >> 128);
        totalSupply = uint128(uint256(fragmentSupply));
    }

    function _constructTokenId(bytes16 groupId, uint128 tokenIndex) private pure returns (uint256 tokenId) {
        // when converting bytes16 to bytes32, the bytes get padded with zeros on the right side.
        tokenId += uint256(bytes32(groupId));
        // when converting uint128 to uint256, the number gets padded with zeros on the left side.
        tokenId += uint256(tokenIndex);
    }
}