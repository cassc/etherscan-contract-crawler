// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {PyramidStorage} from "../libraries/PyramidStorage.sol";

interface IPyramids {
    event itemAddedToPyramid(uint16 pyramidId, uint16 addedItem);

    event itemsAddedToPyramid(uint16 pyramidId, uint16[] addedItems);

    event itemRemovedFromPyramid(uint16 pyramidId, uint16 removedItem);

    event itemsRemovedFromPyramid(
        uint16 pyramidId,
        PyramidStorage.TokenSlot[4] removedItems
    );

    event itemContractUpdated(
        address newItemsContract,
        address oldItemsContract
    );

    function getItemContract() external view returns (address _itemsContract);

    function setItemContract(address _itemsContract) external;

    function getItemType(uint16 _id) external pure returns (uint8);

    function getPyramidSlots(
        uint16 _pyramidId
    ) external view returns (PyramidStorage.TokenSlot[4] memory tokenSlots);

    function addItemsToPyramid(
        uint16 _pyramidId,
        uint16[] calldata _itemIds
    ) external;

    function addItemToPyramid(uint16 _pyramidId, uint16 _itemId) external;

    function removeItemFromPyramid(uint16 _pyramidId, uint16 _itemId) external;

    function removeItemsFromPyramid(uint16 _pyramidId) external;

    function setContractURI(string calldata _contractURI) external;

    function contractURI() external view returns (string memory);
}