// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

import {OnChainPixelArtLibrary} from "./OnChainPixelArtLibrary.sol";
import {Array} from "./Array.sol";

pragma solidity ^0.8.0;

library OnChainPixelArtLibraryv2 {
    using Array for string[];

    uint24 constant COLOR_MASK = 0xFFFFFF;
    //[12 bits startingIndex][12 bits color count][4 bits compression]
    uint8 constant metadataLength = 28;

    struct RenderTracker {
        uint256 colorCompression;
        uint256 pixelCompression;
        uint256 colorCount;
        // tracks which layer in the array of layers
        uint256 layerIndex;
        // tracks which packet within a single layer
        uint256 packet;
        // tracks individual pixel
        uint256 pixel;
        // width of a block to insert
        uint256 width;
        // tracks number of packets accross all layers
        uint256 iterator;
        uint256 x;
        uint256 y;
        uint256 blockSize;
        // x dim * y dim
        uint256 limit;
        // the number of packets including metdata
        uint256 layerOnePackets;
        // pixel compression + color compression
        uint256 packetLength;
        string[] svg;
        uint256 svgIndex;
    }

    struct ComposerTracker {
        uint256 colorCompression;
        uint256 pixelCompression;
        uint256 colorCount;
        uint256 colorOffset;
        uint256 pixel;
        uint256 layerIndex;
        uint256 packet;
        uint256 iterator;
        uint256 numberOfPixels;
        uint256 layerOnePackets;
        uint256 packetLength;
    }

    struct EncoderTracker {
        uint256 colorCompression;
        uint256 layer;
        uint256[] layers;
        uint256 color;
        uint256 packet;
        uint256 numberOfConsecutiveColors;
        uint256 layerIndex;
        uint256 startingIndex;
        uint256 endingIndex;
        uint256 maxConsecutiveColors;
        uint256 packetLength;
        uint256 packetsPerLayer;
        uint256 layerOnePackets;
    }

    string public constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function increment(uint256 x) public pure returns (uint256) {
        unchecked {
            return x + 1;
        }
    }

    function getColorClass(uint256 index) public pure returns (bytes memory) {
        if (index > 26) {
            // we've run out of 2 digit combinations
            if (index > 676) {
                return
                    abi.encodePacked(
                        bytes(TABLE)[index % 26],
                        bytes(TABLE)[(index - 676) / 26],
                        bytes(TABLE)[index / 676]
                    );
            }
            return
                abi.encodePacked(
                    bytes(TABLE)[index % 26],
                    bytes(TABLE)[index / 26]
                );
        }
        return abi.encodePacked(bytes(TABLE)[index % 26]);
    }

    function getViewBox(
        uint256 xDim,
        uint256 yDim,
        uint256 paddingX,
        uint256 paddingY
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    'viewBox="-',
                    OnChainPixelArtLibrary.toString(paddingX),
                    " -",
                    OnChainPixelArtLibrary.toString(paddingY),
                    " ",
                    OnChainPixelArtLibrary.toString(xDim + paddingX * 2),
                    " ",
                    OnChainPixelArtLibrary.toString(yDim + paddingY * 2)
                    //closed by "close" variable in render
                )
            );
    }

    // compressions are number of bits for compresssing
    function render(
        uint256[] memory canvas,
        uint256[] memory palette,
        uint256 xDim,
        uint256 yDim,
        string memory svgExtension,
        uint256 paddingX,
        uint256 paddingY
    ) external pure returns (string memory svg) {
        RenderTracker memory tracker = RenderTracker(
            OnChainPixelArtLibrary.getColorCompression(
                OnChainPixelArtLibrary.getColorCount(canvas)
            ),
            OnChainPixelArtLibrary.getPixelCompression(canvas),
            OnChainPixelArtLibrary.getColorCount(canvas),
            0,
            0,
            OnChainPixelArtLibrary.getStartingIndex(canvas),
            0,
            0,
            0,
            0,
            0,
            yDim * xDim,
            0,
            0,
            new string[](0),
            // svg starts at index 1 because we have a starting svg string
            1
        );

        tracker.packetLength =
            tracker.pixelCompression +
            tracker.colorCompression;

        tracker.layerOnePackets =
            (256 - metadataLength) /
            (tracker.packetLength);

        // breaks cause an extra block, so we need to add yDim for each possible line break
        tracker.svg = new string[](
            ((256 / tracker.packetLength) * canvas.length) + yDim
        );

        string memory close = string(abi.encodePacked('" ', svgExtension, ">"));

        // shave off metadata
        canvas[0] = canvas[0] >> metadataLength;

        tracker.svg[0] = string(
            abi.encodePacked(
                '<svg shape-rendering="crispEdges" xmlns="http://www.w3.org/2000/svg" version="1.2" ',
                getViewBox(xDim, yDim, paddingX, paddingY),
                close,
                OnChainPixelArtLibrary.getColorClasses(
                    palette,
                    tracker.colorCount
                )
            )
        );

        // while pixel is in the bounds of the image
        while (tracker.pixel < tracker.limit) {
            tracker.packet = OnChainPixelArtLibrary.getPacket(
                tracker.iterator,
                tracker.packetLength,
                tracker.layerOnePackets
            );
            // 32 points for every layer of pixel groups
            // uint8 layer = uint8(iterator / packetsPerLayer);
            // 8 bits, 4 bits for color index and 4 bits for up to 16 repetitions
            uint256 numberOfPixels = (canvas[tracker.layerIndex] >>
                ((tracker.packet) * (tracker.packetLength))) &
                OnChainPixelArtLibrary.bitsToMask(tracker.pixelCompression);

            // short circuit the empty pixels at the end of an image
            if (numberOfPixels == 0) {
                break;
            }

            uint256 colorIndex = (canvas[uint8(tracker.layerIndex)] >>
                ((tracker.packet) *
                    (tracker.packetLength) +
                    tracker.pixelCompression)) &
                OnChainPixelArtLibrary.bitsToMask(tracker.colorCompression);

            // colorIndex 1 corresponds to color array index 0
            if (colorIndex > 0) {
                uint256 x = tracker.pixel % xDim;
                uint256 y = tracker.pixel / xDim;

                // calculate how many blocks of pixels we'll need to make
                tracker.blockSize = ((x + numberOfPixels) / xDim) + 1;
                // if we fit the row snuggly, we'll want to remove the 1 we added
                if ((x + numberOfPixels) % xDim == 0) {
                    tracker.blockSize = tracker.blockSize - 1;
                }

                for (
                    uint256 blockCounter;
                    blockCounter < tracker.blockSize;
                    blockCounter = increment(blockCounter)
                ) {
                    x = tracker.pixel % xDim;
                    y = tracker.pixel / xDim;

                    // check that the block overflows into the next row
                    if (numberOfPixels > xDim - x) {
                        tracker.width = xDim - x;
                    } else {
                        tracker.width = numberOfPixels;
                    }
                    tracker.pixel = tracker.pixel + tracker.width;
                    tracker.svg[tracker.svgIndex] = string(
                        abi.encodePacked(
                            svg,
                            '<rect x="',
                            OnChainPixelArtLibrary.toString(x),
                            '" y="',
                            OnChainPixelArtLibrary.toString(y),
                            '" width="',
                            OnChainPixelArtLibrary.toString(tracker.width),
                            '" height="1" class="',
                            getColorClass(colorIndex - 1),
                            '"/>'
                        )
                    );
                    numberOfPixels = numberOfPixels - tracker.width;
                    tracker.svgIndex += 1;
                }
            } else {
                // we still need to account for the empty pixels
                tracker.pixel = tracker.pixel + numberOfPixels;
            }

            tracker.iterator += 1;

            tracker.layerIndex = OnChainPixelArtLibrary.getLayerIndex(
                tracker.iterator,
                tracker.packetLength,
                tracker.layerOnePackets
            );
        }

        tracker.svg[tracker.iterator + 1] = "</svg>";

        return tracker.svg.join();
    }
}