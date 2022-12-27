// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

interface IEditionsExtension {
    struct EditionInfo {
        uint256 royaltiesBps;
        string name;
        string editionURI;
    }

    function registerEdition(
        EditionInfo calldata info,
        address creator,
        uint256 listingId
    ) external;

    function mintEdition(uint256 listingId, address receiver, uint256 amount) external;
}