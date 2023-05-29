// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEnhanceable {
    struct EnhancementRequest {
        uint256 id;
        address requester;
    }

    event EnhancementRequested(
        uint256 indexed tokenId,
        uint256 indexed timestamp
    );

    event EnhancementCompleted(
        uint256 indexed tokenId,
        uint256 indexed timestamp,
        bool success,
        bool degraded
    );

    event SeederUpdated(address indexed caller, address indexed seeder);

    function enhancementCost(uint256 tokenId)
        external
        view
        returns (uint256, bool);

    function enhance(uint256 tokenId, uint256 burnTokenId) external;
}