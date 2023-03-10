// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "./LibERC721MintData.sol";

library LibERC721Permit {
    bytes32 public constant ERC721_PERMIT_TYPE_HASH =
        keccak256("ERC721Permit(address owner,address to,uint256 tokenId,uint256 nonce,uint256 deadline)");

    bytes32 public constant ERC721_PERMIT_FOR_ALL_TYPE_HASH =
        keccak256("ERC721PermitForAll(address owner,address operator,bool approved,uint256 nonce,uint256 deadline)");

    bytes32 public constant ERC721_MINT_WITH_PERMIT_TYPE_HASH =
        keccak256(
            "ERC721MintWithPermit(address minter,MintData mintData,uint256 nonce,uint256 deadline)MintData(address to,uint256 tokenId,InitialMintData initialData)InitialMintData(string tokenURI,bytes32 cidDigest,Share royalty)Share(address account,uint16 value)"
        );

    function hashPermit(
        address owner,
        address to,
        uint256 tokenId,
        uint256 nonce,
        uint256 deadline
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(ERC721_PERMIT_TYPE_HASH, owner, to, tokenId, nonce, deadline));
    }

    function hashPermitForAll(
        address owner,
        address operator,
        bool approved,
        uint256 nonce,
        uint256 deadline
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(ERC721_PERMIT_FOR_ALL_TYPE_HASH, owner, operator, approved, nonce, deadline));
    }

    function hashMintWithPermit(
        address minter,
        LibERC721MintData.MintData calldata mintData,
        uint256 nonce,
        uint256 deadline
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ERC721_MINT_WITH_PERMIT_TYPE_HASH,
                    minter,
                    LibERC721MintData.hashMintData(mintData),
                    nonce,
                    deadline
                )
            );
    }
}