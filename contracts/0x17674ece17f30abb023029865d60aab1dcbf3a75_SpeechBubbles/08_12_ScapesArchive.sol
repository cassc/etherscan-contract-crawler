// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "hardhat/console.sol";
import "./WithArchiveMaster.sol";

/// @title Archive of Elements of the ScapeLand
contract ScapesArchive is WithArchiveMaster {

    /// @title Metadata for an archived element from ScapeLand
    /// @param format The format in which the data is stored (PNG/SVG/...)
    /// @param collectionId Documented off chain
    /// @param isObject False implies background
    /// @param width The true pixel width of the element
    /// @param height The true pixel height of the element
    /// @param x The default offset from the left
    /// @param y The default offset from the top
    /// @param zIndex Default z-index of the element
    /// @param canFlipX The element can be flipped horizontally
    /// @param canFlipY Can be flipped vertically without obscuring content
    /// @param seamlessX The element can be tiled horizontally
    /// @param seamlessY The element can be tiled vertically
    /// @param addedAt Automatically freezes after 1 week
    struct ElementMetadata {
        uint8   format;
        uint16  collectionId;
        bool    isObject;
        uint16  width;
        uint16  height;
        int16   x;
        int16   y;
        uint8   zIndex;
        bool    canFlipX;
        bool    canFlipY;
        bool    seamlessX;
        bool    seamlessY;
        uint64  addedAt;
    }

    /// @title An archived element from ScapeLand
    /// @param data The raw data (normally the image)
    /// @param metadata The elements' configuration data
    struct Element {
        bytes data;
        ElementMetadata metadata;
    }

    /// @dev category => (itemName => itemData)
    mapping(string => mapping(string => Element)) private categories;

    /// @notice Archive an item
    /// @param category The name of the category
    /// @param names A list of element names
    /// @param elements A list of elements to store
    function storeElements(
        string calldata category,
        string[] calldata names,
        Element[] calldata elements
    )
        public onlyOwner
    {
        require(names.length == elements.length, "Must have a name for each item.");

        for (uint256 index = 0; index < names.length; index++) {
            uint64 _now = uint64(block.timestamp);
            Element memory current = categories[category][names[index]];
            require(
                current.metadata.addedAt == 0 || (current.metadata.addedAt + 4 weeks) > _now,
                "Already locked."
            );

            Element memory element = elements[index];
            element.metadata.addedAt = _now;
            categories[category][names[index]] = element;
        }
    }

    /// @notice Update the metadata of an archived element
    /// @param category The name of the category
    /// @param names A list of element names
    /// @param elementsData A list of elements metadata to store
    function updateElementsMetadata(
        string calldata category,
        string[] calldata names,
        ElementMetadata[] calldata elementsData
    )
        public onlyOwner
    {
        require(names.length == elementsData.length, "Must have a name for each item.");

        for (uint256 index = 0; index < names.length; index++) {
            uint64 _now = uint64(block.timestamp);
            Element memory current = categories[category][names[index]];
            require(current.metadata.addedAt > 0, "Doesn't exist.");
            require(current.metadata.addedAt + 4 weeks > _now, "Already locked.");

            ElementMetadata memory metadata = elementsData[index];
            metadata.addedAt = _now;
            categories[category][names[index]].metadata = metadata;
        }
    }

    /// @notice Get the bare data for an archived item
    /// @param category The category of the element
    /// @param name The identifying name of the element
    function getElement(string memory category, string memory name)
        public view
        returns (Element memory item)
    {
        item = categories[category][name];
    }

}