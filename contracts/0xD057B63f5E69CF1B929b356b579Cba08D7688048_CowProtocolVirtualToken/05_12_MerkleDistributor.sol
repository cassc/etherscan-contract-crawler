// SPDX-License-Identifier: LGPL-3.0-or-later

// This contract is based on Uniswap's MekleDistributor, which can be found at:
// https://github.com/Uniswap/merkle-distributor/blob/0d478d722da2e5d95b7292fd8cbdb363d98e9a93/contracts/MerkleDistributor.sol
//
// The changes between the original contract and this are:
//  - the claim function doesn't trigger a transfer on a successful proof, but
//    it executes a dedicated (virtual) function.
//  - added a claimMany function for bundling multiple claims in a transaction
//  - supported sending an amount of native tokens along with the claim
//  - added the option of claiming less than the maximum amount
//  - gas optimizations in the packing and unpacking of the claimed bit
//  - bumped Solidity version
//  - code formatting

pragma solidity ^0.8.10;

import "../vendored/interfaces/IERC20.sol";
import "../vendored/libraries/MerkleProof.sol";

import "../interfaces/ClaimingInterface.sol";

abstract contract MerkleDistributor is ClaimingInterface {
    bytes32 public immutable merkleRoot;

    /// @dev Event fired if a claim was successfully performed.
    event Claimed(
        uint256 index,
        ClaimType claimType,
        address claimant,
        uint256 claimableAmount,
        uint256 claimedAmount
    );

    /// @dev Error caused by a user trying to call the claim function for a
    /// claim that has already been used before.
    error AlreadyClaimed();
    /// @dev Error caused by a user trying to claim a larger amount than the
    /// maximum allowed in the claim.
    error ClaimingMoreThanMaximum();
    /// @dev Error caused by the caller trying to perform a partial claim while
    /// not being the owner of the claim.
    error OnlyOwnerCanClaimPartially();
    /// @dev Error caused by calling the claim function with an invalid proof.
    error InvalidProof();
    /// @dev Error caused by calling claimMany with a transaction value that is
    /// different from the required one.
    error InvalidNativeTokenValue();

    /// @dev Packed array of booleans that stores if a claim is available.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(bytes32 merkleRoot_) {
        merkleRoot = merkleRoot_;
    }

    /// @dev Checks if the claim at the provided index has already been claimed.
    /// @param index The index to check.
    /// @return Whether the claim at the given index has already been claimed.
    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index >> 8;
        uint256 claimedBitIndex = index & 0xff;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask != 0;
    }

    /// @dev Mark the provided index as having been claimed.
    /// @param index The index that was claimed.
    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index >> 8;
        uint256 claimedBitIndex = index & 0xff;
        claimedBitMap[claimedWordIndex] =
            claimedBitMap[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    /// @dev This function verifies the provided input proof based on the
    /// provided input. If the proof is valid, the function [`performClaim`] is
    /// called for the claimed amount.
    /// @param index The index that identifies the input claim.
    /// @param claimType See [`performClaim`].
    /// @param claimant See [`performClaim`].
    /// @param claimableAmount The maximum amount that the claimant can claim
    /// for this claim. Should not be smaller than claimedAmount.
    /// @param claimedAmount See [`performClaim`].
    /// @param merkleProof A proof that the input claim belongs to the unique
    /// Merkle root associated to this contract.
    function claim(
        uint256 index,
        ClaimType claimType,
        address claimant,
        uint256 claimableAmount,
        uint256 claimedAmount,
        bytes32[] calldata merkleProof
    ) external payable {
        _claim(
            index,
            claimType,
            claimant,
            claimableAmount,
            claimedAmount,
            merkleProof,
            msg.value
        );
    }

    /// @dev This function verifies and executes multiple claims in the same
    /// transaction.
    /// @param indices A vector of indices. See [`claim`] for details.
    /// @param claimTypes A vector of claim types. See [`performClaim`] for
    /// details.
    /// @param claimants A vector of claimants. See [`performClaim`] for
    /// details.
    /// @param claimableAmounts A vector of claimable amounts. See [`claim`] for
    /// details.
    /// @param claimedAmounts A vector of claimed amounts. See [`performClaim`]
    /// for details.
    /// @param merkleProofs A vector of merkle proofs. See [`claim`] for
    /// details.
    /// @param sentNativeTokens A vector of native token amounts. See
    /// [`performClaim`] for details.
    function claimMany(
        uint256[] memory indices,
        ClaimType[] memory claimTypes,
        address[] calldata claimants,
        uint256[] calldata claimableAmounts,
        uint256[] calldata claimedAmounts,
        bytes32[][] calldata merkleProofs,
        uint256[] calldata sentNativeTokens
    ) external payable {
        uint256 sumSentNativeTokens;
        for (uint256 i = 0; i < indices.length; i++) {
            sumSentNativeTokens += sentNativeTokens[i];
            _claim(
                indices[i],
                claimTypes[i],
                claimants[i],
                claimableAmounts[i],
                claimedAmounts[i],
                merkleProofs[i],
                sentNativeTokens[i]
            );
        }
        if (sumSentNativeTokens != msg.value) {
            revert InvalidNativeTokenValue();
        }
    }

    /// @dev This function verifies the provided input proof based on the
    /// provided input. If the proof is valid, the function [`performClaim`] is
    /// called for the claimed amount.
    /// @param index See [`claim`].
    /// @param claimType See [`performClaim`].
    /// @param claimant See [`performClaim`].
    /// @param claimableAmount See [`claim`].
    /// @param claimedAmount See [`performClaim`].
    /// @param merkleProof See [`claim`].
    /// @param sentNativeTokens See [`performClaim`].
    function _claim(
        uint256 index,
        ClaimType claimType,
        address claimant,
        uint256 claimableAmount,
        uint256 claimedAmount,
        bytes32[] calldata merkleProof,
        uint256 sentNativeTokens
    ) private {
        if (isClaimed(index)) {
            revert AlreadyClaimed();
        }
        if (claimedAmount > claimableAmount) {
            revert ClaimingMoreThanMaximum();
        }
        if ((claimedAmount < claimableAmount) && (msg.sender != claimant)) {
            revert OnlyOwnerCanClaimPartially();
        }

        // Note: all types used inside `encodePacked` should have fixed length,
        // otherwise the same proof could be used in different claims.
        bytes32 node = keccak256(
            abi.encodePacked(index, claimType, claimant, claimableAmount)
        );
        if (!MerkleProof.verify(merkleProof, merkleRoot, node)) {
            revert InvalidProof();
        }

        _setClaimed(index);

        performClaim(
            claimType,
            msg.sender,
            claimant,
            claimedAmount,
            sentNativeTokens
        );

        emit Claimed(
            index,
            claimType,
            claimant,
            claimableAmount,
            claimedAmount
        );
    }
}