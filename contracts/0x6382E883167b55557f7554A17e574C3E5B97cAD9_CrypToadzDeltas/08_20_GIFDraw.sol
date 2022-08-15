// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "./GIFFrame.sol";
import "./IPixelRenderer.sol";

library GIFDraw {
    function draw(
        IPixelRenderer renderer,
        GIFFrame memory frame,
        bytes memory buffer,
        uint256 position,
        uint8 offsetX,
        uint8 offsetY,
        bool blend
    ) internal pure returns (uint256) {
        (uint32[] memory colors, uint256 positionAfterColor) = renderer.getColorTable(buffer, position);
        position = positionAfterColor;

        (uint32[] memory newBuffer, uint256 positionAfterDraw) = renderer.drawFrameWithOffsets(
            DrawFrame(
                buffer,
                position,
                frame,
                colors,
                offsetX,
                offsetY,
                blend
            )
        );

        frame.buffer = newBuffer;
        return positionAfterDraw;
    }
}