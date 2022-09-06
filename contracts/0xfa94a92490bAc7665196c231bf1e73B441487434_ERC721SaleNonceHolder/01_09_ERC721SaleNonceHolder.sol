// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import "../roles/OperatorRole.sol";

contract ERC721SaleNonceHolder is OperatorRole {
    // keccak256(token, owner, tokenId) => nonce
    mapping(bytes32 => uint256) public nonces;

    /**
     * @notice returns nonce value
     * @param token ERC721 token address
     * @param tokenId Id of token
     * @param owner owner of token
     */
    function getNonce(
        address token,
        uint256 tokenId,
        address owner
    ) external view returns (uint256) {
        return nonces[getNonceKey(token, tokenId, owner)];
    }

    /**
     * @notice set nonce value
     * @param token ERC721 token address
     * @param tokenId Id of token
     * @param owner owner of token
     * @param nonce nonce value
     */
    function setNonce(
        address token,
        uint256 tokenId,
        address owner,
        uint256 nonce
    ) external onlyOperator {
        nonces[getNonceKey(token, tokenId, owner)] = nonce;
    }

    /**
     * @notice returns hashed nonce key
     * @param token ERC721 token address
     * @param tokenId Id of token
     * @param owner owner of token
     */
    function getNonceKey(
        address token,
        uint256 tokenId,
        address owner
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(token, tokenId, owner));
    }
}