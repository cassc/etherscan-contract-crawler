// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract ForeverFrogsEgg {
    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
        bool burned;
        uint24 extraData;
    }

    function isApprovedForAll(address owner, address operator) external view virtual returns (bool);

    function explicitOwnershipOf(uint256 tokenId) external view virtual returns (TokenOwnership memory);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual payable;
}