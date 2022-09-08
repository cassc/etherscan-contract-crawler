// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILayerable {
    function getLayerImageURI(uint256 layerId)
        external
        view
        returns (string memory);

    function getLayeredTokenImageURI(uint256[] calldata activeLayers)
        external
        view
        returns (string memory);

    function getBoundLayerTraits(uint256 bindings)
        external
        view
        returns (string memory);

    function getActiveLayerTraits(uint256[] calldata activeLayers)
        external
        view
        returns (string memory);

    function getBoundAndActiveLayerTraits(
        uint256 bindings,
        uint256[] calldata activeLayers
    ) external view returns (string memory);

    function getTokenURI(
        uint256 tokenId,
        uint256 layerId,
        uint256 bindings,
        uint256[] calldata activeLayers,
        bytes32 layerSeed
    ) external view returns (string memory);
}