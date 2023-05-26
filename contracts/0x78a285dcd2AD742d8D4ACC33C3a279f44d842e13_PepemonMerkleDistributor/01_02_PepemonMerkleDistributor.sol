// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IPepemonFactory {
    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) external;
}

contract PepemonMerkleDistributor {
    event Claimed(
        uint256 tokenId,
        uint256 index,
        address account,
        uint256 amount
    );

    IPepemonFactory public factory;
    mapping(uint256 => bytes32) merkleRoots;
    mapping(uint256 => mapping(uint256 => uint256)) private claimedTokens;

    // @dev do not use 0 for tokenId
    constructor(
        address pepemonFactory_,
        bytes32[] memory merkleRoots_,
        uint256[] memory pepemonIds_
    ) {
        require(pepemonFactory_ != address(0), "ZeroFactoryAddress");
        require(
            merkleRoots_.length == pepemonIds_.length,
            "RootsIdsCountMismatch"
        );

        factory = IPepemonFactory(pepemonFactory_);

        for (uint256 r = 0; r < merkleRoots_.length; r++) {
            merkleRoots[pepemonIds_[r]] = merkleRoots_[r];
        }
    }

    function isClaimed(uint256 pepemonTokenId, uint256 index)
        public
        view
        returns (bool)
    {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedTokens[pepemonTokenId][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function claim(
        uint256 tokenId,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        require(merkleRoots[tokenId] != 0, "UnknownTokenId");
        require(
            !isClaimed(tokenId, index),
            "MerkleDistributor: Drop already claimed"
        );

        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(
            MerkleProof.verify(merkleProof, merkleRoots[tokenId], node),
            "MerkleDistributor: Invalid proof"
        );

        _setClaimed(tokenId, index);

        factory.mint(account, tokenId, 1, "");

        emit Claimed(tokenId, index, account, amount);
    }

    function _setClaimed(uint256 pepemonTokenId, uint256 index) internal {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedTokens[pepemonTokenId][claimedWordIndex] =
            claimedTokens[pepemonTokenId][claimedWordIndex] |
            (1 << claimedBitIndex);
    }
}