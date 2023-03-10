// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "./LibShare.sol";

library LibERC721MintData {
    struct InitialMintData {
        string tokenURI;
        bytes32 cidDigest;
        LibShare.Share royalty;
    }

    struct MintData {
        address to;
        uint256 tokenId;
        InitialMintData initialData;
    }

    bytes32 private constant INITIAL_MINT_DATA_TYPE_HASH =
        keccak256(
            "InitialMintData(string tokenURI,bytes32 cidDigest,Share royalty)Share(address account,uint16 value)"
        );

    bytes32 private constant MINT_DATA_TYPE_HASH =
        keccak256(
            "MintData(address to,uint256 tokenId,InitialMintData initialData)InitialMintData(string tokenURI,bytes32 cidDigest,Share royalty)Share(address account,uint16 value)"
        );

    function hashInitialMintData(InitialMintData calldata data) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    INITIAL_MINT_DATA_TYPE_HASH,
                    keccak256(bytes(data.tokenURI)),
                    data.cidDigest,
                    LibShare.hash(data.royalty)
                )
            );
    }

    function hashMintData(MintData calldata data) internal pure returns (bytes32) {
        return keccak256(abi.encode(MINT_DATA_TYPE_HASH, data.to, data.tokenId, hashInitialMintData(data.initialData)));
    }
}