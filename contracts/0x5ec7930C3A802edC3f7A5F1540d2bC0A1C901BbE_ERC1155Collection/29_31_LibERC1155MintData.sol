// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "./LibShare.sol";

library LibERC1155MintData {
    struct InitialMintData {
        string tokenURI;
        bytes32 cidDigest;
        uint256 maxSupply;
        LibShare.Share royalty;
    }

    struct MintData {
        address to;
        uint256 id;
        uint256 amount;
        InitialMintData initialData;
    }

    struct MintBatchData {
        address to;
        uint256[] ids;
        uint256[] amounts;
        InitialMintData[] initialData;
    }

    bytes32 private constant INITIAL_MINT_DATA_TYPE_HASH =
        keccak256(
            "InitialMintData(string tokenURI,bytes32 cidDigest,uint256 maxSupply,Share royalty)Share(address account,uint16 value)"
        );

    bytes32 private constant MINT_DATA_TYPE_HASH =
        keccak256(
            "MintData(address to,uint256 id,uint256 amount,InitialMintData initialData)InitialMintData(string tokenURI,bytes32 cidDigest,uint256 maxSupply,Share royalty)Share(address account,uint16 value)"
        );

    bytes32 private constant MINT_BATCH_DATA_TYPE_HASH =
        keccak256(
            "MintBatchData(address to,uint256[] ids,uint256[] amounts,InitialMintData[] initialData)InitialMintData(string tokenURI,bytes32 cidDigest,uint256 maxSupply,Share royalty)Share(address account,uint16 value)"
        );

    function hashInitialMintData(InitialMintData calldata data) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    INITIAL_MINT_DATA_TYPE_HASH,
                    keccak256(bytes(data.tokenURI)),
                    data.cidDigest,
                    data.maxSupply,
                    LibShare.hash(data.royalty)
                )
            );
    }

    function hashMintData(MintData calldata data) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(MINT_DATA_TYPE_HASH, data.to, data.id, data.amount, hashInitialMintData(data.initialData))
            );
    }

    function hashMintBatchData(MintBatchData calldata data) internal pure returns (bytes32) {
        bytes32[] memory initialDataHashes = new bytes32[](data.initialData.length);
        for (uint256 i = 0; i < data.initialData.length; i++) {
            initialDataHashes[i] = hashInitialMintData(data.initialData[i]);
        }
        return
            keccak256(
                abi.encode(
                    MINT_DATA_TYPE_HASH,
                    data.to,
                    data.ids,
                    data.amounts,
                    keccak256(abi.encodePacked(initialDataHashes))
                )
            );
    }
}