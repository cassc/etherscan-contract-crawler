//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../interfaces/INarratorsHut.sol";

library Signatures {
    // Typehashes for the data types specified in the structured data
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#rationale-for-typehash
    // This should match whats in the client side signing code
    bytes32 constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes constant TOKEN_DATA_TYPE_DEF =
        "TokenData(uint32 artifactId,uint32 witchId)";
    bytes32 constant MINT_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "Mint(address minterAddress,uint256 totalCost,uint256 expiresAt,TokenData[] tokenDataArray)",
                TOKEN_DATA_TYPE_DEF
            )
        );
    bytes32 constant TOKEN_DATA_TYPEHASH = keccak256(TOKEN_DATA_TYPE_DEF);

    // Verify signature by recreating the hash that we signed on
    // the client side, and then using that to recover
    // the address that signed the signature for this data.
    function recreateMintHash(
        bytes32 domainSeparator,
        address minterAddress,
        uint256 totalCost,
        uint256 expiresAt,
        TokenData[] calldata tokenDataArray
    ) internal pure returns (bytes32) {
        bytes32 mintHash = _hashMint(
            minterAddress,
            totalCost,
            expiresAt,
            tokenDataArray
        );

        return _eip712Message(domainSeparator, mintHash);
    }

    function _hashMint(
        address minterAddress,
        uint256 totalCost,
        uint256 expiresAt,
        TokenData[] calldata tokenDataArray
    ) private pure returns (bytes32) {
        bytes32[] memory tokenDataHashes = new bytes32[](tokenDataArray.length);
        for (uint256 i; i < tokenDataArray.length; ) {
            tokenDataHashes[i] = _hashTokenData(tokenDataArray[i]);
            unchecked {
                ++i;
            }
        }

        return
            keccak256(
                abi.encode(
                    MINT_TYPEHASH,
                    minterAddress,
                    totalCost,
                    expiresAt,
                    keccak256(abi.encodePacked(tokenDataHashes))
                )
            );
    }

    function _hashTokenData(TokenData calldata tokenData)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    TOKEN_DATA_TYPEHASH,
                    tokenData.artifactId,
                    tokenData.witchId
                )
            );
    }

    function _eip712Message(bytes32 domainSeparator, bytes32 dataHash)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(uint16(0x1901), domainSeparator, dataHash)
            );
    }
}