// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.11;

struct BaselArtFixedPriceDrop {
    address collection;
    uint256[] itemIds;
    uint128 price;
    uint256 start;
    bool cancelled;
    uint32 numMinted;
}

interface IBaselArtFixedPriceSale {
    function setMinter(address minter) external;

    function drop(uint256 dropId)
        external
        view
        returns (
            address,
            uint256[] memory,
            uint128,
            uint256,
            bool,
            uint32
        );

    function remainingItems(uint256 dropId) external view returns (uint32);

    function publishDrop(
        uint256 dropId,
        address collection,
        uint256[] calldata itemIds,
        uint128 price,
        uint256 start
    ) external;

    function rePublishDrop(
        uint256 dropId,
        uint256[] calldata itemIds,
        uint128 price,
        uint256 start
    ) external;

    function cancelDrop(uint256 dropId) external;
}