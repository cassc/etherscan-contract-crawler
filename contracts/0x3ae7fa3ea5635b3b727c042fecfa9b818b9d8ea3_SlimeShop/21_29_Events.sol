// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface BoundLayerableEvents {
    event LayersBoundToToken(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed boundLayersBitmap
    );

    event ActiveLayersChanged(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed activeLayersBytearray
    );
}