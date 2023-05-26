// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library Errors {
    error NoCorrespondingIdentity();

    error MintNotStarted();

    error CannotMintMore(uint256 minted, uint256 maxAllowedToMint);

    error NotBeApprovedOrOwner(address caller, uint256 tokenId);

    error OutOfLastLevel(uint256 inputLevel, uint256 lastLevel);

    error InsufficientPoints(uint256 ownedPoints, uint256 requiredPoints);

    error CannotBeSet(uint256 level);

    error InvalidPoints(uint256 points);

    error NotCurrentStage(bytes32 inputStage);

    error NotNextStage(bytes32 inputStage);

    error NoMoreStage();
}