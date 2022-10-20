// SPDX-License-Identifier: MIT
// Creator: JCBDEV (Quantum Art)

pragma solidity ^0.8.4;

library TokenId {
    uint256 private constant _baseIdMask = ~uint256(type(uint128).max);

    /// @notice Generate a token id
    /// @param drop The drop id the token belongs to
    /// @param mint The sequence number of the token minted
    /// @return tokenId the token id
    function from(uint128 drop, uint128 mint)
        internal
        pure
        returns (uint256 tokenId)
    {
        tokenId |= uint256(drop) << 128;
        tokenId |= uint256(mint);

        return tokenId;
    }

    /// @notice Get the first token Id in the range for the same stop as the token id
    /// @param tokenId The token id to check the drop range
    /// @return uint128 the first token in this drop range
    function firstTokenInDrop(uint256 tokenId) internal pure returns (uint256) {
        return tokenId & _baseIdMask;
    }

    /// @notice extract the drop id from the token id
    /// @param tokenId The token id to extract the values from
    /// @return uint128 the drop id
    function dropId(uint256 tokenId) internal pure returns (uint128) {
        return uint128(tokenId >> 128);
    }

    /// @notice extract the sequence number from the token id
    /// @param tokenId The token id to extract the values from
    /// @return uint128 the sequence number
    function mintId(uint256 tokenId) internal pure returns (uint128) {
        return uint128(tokenId);
    }

    /// @notice extract the drop id and the sequence number from the token id
    /// @param tokenId The token id to extract the values from
    /// @return uint128 the drop id
    /// @return uint128 the sequence number
    function split(uint256 tokenId) internal pure returns (uint128, uint128) {
        return (uint128(tokenId >> 128), uint128(tokenId));
    }
}