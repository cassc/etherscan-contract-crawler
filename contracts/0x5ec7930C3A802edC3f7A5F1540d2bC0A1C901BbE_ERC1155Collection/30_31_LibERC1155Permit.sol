// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "./LibERC1155MintData.sol";

library LibERC1155Permit {
    bytes32 private constant ERC1155_PERMIT_FOR_ALL_TYPE_HASH =
        keccak256("ERC1155PermitForAll(address owner,address operator,bool approved,uint256 nonce,uint256 deadline)");

    bytes32 private constant ERC1155_MINT_BATCH_WITH_PERMIT_TYPE_HASH =
        keccak256(
            "ERC1155MintBatchWithPermit(address minter,MintBatchData mintData,uint256 nonce,uint256 deadline)InitialMintData(string tokenURI,bytes32 cidDigest,uint256 maxSupply,Share royalty)MintBatchData(address to,uint256[] ids,uint256[] amounts,InitialMintData[] initialData)Share(address account,uint16 value)"
        );

    function hashPermitForAll(
        address owner,
        address operator,
        bool approved,
        uint256 nonce,
        uint256 deadline
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(ERC1155_PERMIT_FOR_ALL_TYPE_HASH, owner, operator, approved, nonce, deadline));
    }

    function hashMintBatchWithPermit(
        address minter,
        LibERC1155MintData.MintBatchData calldata mintData,
        uint256 nonce,
        uint256 deadline
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ERC1155_MINT_BATCH_WITH_PERMIT_TYPE_HASH,
                    minter,
                    LibERC1155MintData.hashMintBatchData(mintData),
                    nonce,
                    deadline
                )
            );
    }
}