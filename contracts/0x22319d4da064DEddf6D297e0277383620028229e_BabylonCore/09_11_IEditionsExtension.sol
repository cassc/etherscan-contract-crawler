// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

interface IEditionsExtension {
    function registerEdition(
        address creator,
        uint256 listingId,
        uint256 royaltiesBps,
        string calldata editionURI
    ) external;

    function mintEdition(uint256 listingId, address receiver, uint256 amount) external;
}