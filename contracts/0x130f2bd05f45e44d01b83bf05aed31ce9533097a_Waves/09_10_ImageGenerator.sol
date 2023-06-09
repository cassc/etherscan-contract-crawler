// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./utils/Base64.sol";
import "./utils/ToString.sol";

library ImageGenerator  {

    /**
     * @dev Generates the 10x10 grid of circles that compose the wave
     */
    function generateGrid(string memory ellipseSize) private pure returns (bytes memory){
        bytes memory row;

        uint256 cx = 20;
        uint256 cy = 0;
        uint256 from = 20;
        uint256 begin = 0;
        uint256 beginHelper = 0;
        uint256 animationDelay = 0;

        for(uint256 i; i < 10; i++) {
            for(uint256 j; j < 10; j++) {
                row = abi.encodePacked(
                    row,
                    '<circle cx="',
                    ToString.toString(cx),
                    '" cy="',
                    ToString.toString(cy),
                    '" r="',
                    ellipseSize,
                    '" class="color-animation" style="animation-delay: ',
                    ToString.toString(animationDelay),
                    'ms"> <animateTransform attributeName="transform" type="rotate" from="0 ',
                    ToString.toString(cx),
                    ' ',
                    ToString.toString(from),
                    '" to="360 ',
                    ToString.toString(cx),
                    ' ',
                    ToString.toString(from),
                    '" begin="',
                    ToString.toString(begin),
                    'ms" dur="3000ms" repeatCount="indefinite" /> </circle>'
                );
                cy += 40;
                from += 40;
                begin += 300;
                animationDelay += 300;
            }
            cx += 40;
            cy = 0;
            from = 20;
            beginHelper += 300;
            begin = beginHelper;
            animationDelay = 300 + 300*(i+1);
        }

        return row;
    }

    /**
     * @dev Generates the SVG used as image (preview) of the wave
     */
    function createWave(string memory waveColor, string memory ellipseSize, string memory colorVariation) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                '<svg viewBox="0 0 400 400" xmlns="http://www.w3.org/2000/svg" style="background-color: black" > <style> :root { --variation: ',
                colorVariation,
                'deg;--color:',
                waveColor,
                'deg; } .color-animation { animation-name: color-change; animation-duration: 1.5s; animation-direction: alternate; animation-iteration-count:infinite; animation-fill-mode: forwards; } @keyframes color-change { 0% { fill: hsl(calc(var(--color) - var(--variation)*1), 100%, 50%); } 20% { fill: hsl(calc(var(--color) - var(--variation)*0.8), 100%, 50%); } 40% { fill: hsl(calc(var(--color) - var(--variation)*0.6), 100%, 50%); } 60% { fill: hsl(calc(var(--color) - var(--variation)*0.4), 100%, 50%); } 80% { fill: hsl(calc(var(--color) - var(--variation)*0.2), 100%, 50%); } 100% { fill: hsl(calc(var(--color) - var(--variation)*0), 100%, 50%); } } </style> <g id="grid" fill="hsl(var(--color), 100%, 50%)">',
                generateGrid(ellipseSize),
                '</g></svg>'
            )
        );
    }

}