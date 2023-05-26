// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./IKitten.sol";

interface IMetadata {
    function getPlaceholderURI(uint256 tokenId) external view returns (string memory);

    function getTokenURI(uint256 tokenId, IKitten.Kitten calldata kitten, bool offChain)
        external
        view
        returns (string memory);

    function uploadTraits(
        uint8 trait,
        uint8[] calldata traitIds,
        string[] calldata names,
        string[] calldata images
    ) external;
}