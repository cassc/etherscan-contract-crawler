// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IAtticNFT {
    event AdminMint(address to, uint64 quantity);
    event MekleMint(address to, uint64 quantity);
    event FreeMintPermit(address to, uint64 quantity);
    event PublicMint(address to, uint64 quantity);
    event ScoreMint(address to, uint64 quantity);
    event SetFreeMintMerkleRoot(bytes32 root, bytes32 list);
    event SetPublicMintMerkleRoot(bytes32 root, bytes32 list);
    event ERC721Received(address contractAddress, address _operator, address _from, uint256 _tokenId, bytes _data);
}