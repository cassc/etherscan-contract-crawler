// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IInteractor {
    error InvalidInteraction();
    error InvalidData();

    event InteractionDataUpdated(
        address indexed user,
        address indexed tokenContract,
        uint256 indexed tokenId,
        bytes data
    );

    function isValidInteraction(
        address user,
        address tokenContract,
        uint256 tokenId,
        bytes calldata interactionData,
        bytes calldata validationData
    ) external view returns (bool);

    function getInteractionData(
        address tokenContract,
        uint256 tokenId
    ) external view returns (bytes memory buffer, uint8);

    function interact(
        address user,
        uint256 tokenId,
        bytes calldata interactionData,
        bytes calldata validationData
    ) external;
}