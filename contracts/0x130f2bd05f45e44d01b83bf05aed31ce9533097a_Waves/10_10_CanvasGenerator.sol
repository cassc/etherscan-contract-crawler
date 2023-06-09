// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./utils/Base64.sol";
import "./utils/ToString.sol";

library CanvasGenerator {

    string constant start = '<html><head> <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/p5.js/1.1.9/p5.js" ></script> <style> html, body { overflow: hidden; margin: 0; padding: 0; background:white; } </style> </head> <body> <main id="textOutput-content"><canvas style="width: 0px; height: 0px;"></canvas></main> <script type="text/javascript">const gridSize = ';
    string constant ellipse = ',ellipseSize = ';
    string constant step = ',tStep =';
    string constant hueVariation = ',hueVariation =';
    string constant base = ',baseHue ='; 
    string constant end = ',saturation = 100; let t = 0; function setup() { createCanvas(windowWidth+100, windowHeight+100); colorMode(HSB, 360, 100, 100, 100); noStroke(); } function draw() { background(0, 0, 10, 8); for (let x = 0; x <= width; x += gridSize) { for (let y = 0; y <= height; y += gridSize) { const angleOffsetX = map(mouseX, 0, width, -2 * PI, 2 * PI, true), angleOffsetY = map(mouseY, 0, height, -2 * PI, 2 * PI, true), angleOffsetXY = map((mouseX + mouseY) / 2, 0, (width + height) / 2, -2 * PI, 2 * PI, true), angle1 = angleOffsetX * (x / width), angle2 = angleOffsetY * (y / height), angle3 = angleOffsetXY * (sqrt(sq(x) + sq(y)) / sqrt(sq(width) + sq(height))), myX = x + 20 * cos(2 * PI * t + angle1 + angle2 + angle3), myY = y + 20 * sin(2 * PI * t + angle1 + angle2 + angle3), distanceToNeighbor = dist(myX, myY, x + gridSize, y), provisionalHue = baseHue - hueVariation, hueValue = (map(distanceToNeighbor, 8, 50, provisionalHue, baseHue) % 360 + 360) % 360; fill(hueValue, saturation, 100); ellipse(myX, myY, ellipseSize); } } t += tStep; }  function windowResized() { resizeCanvas(windowWidth, windowHeight); } new p5();</script></body></html>';

    /**
     * @dev Generates the HTML used as animation of the wave, credits to Aatish Bhatia for the inspiration
     */
    function generateCustomCanvas(string memory waveColor, string memory gridSize, string memory ellipseSize, string memory animationSpeed, string memory variation) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                start,
                gridSize,
                ellipse,
                ellipseSize,
                step,
                animationSpeed,
                hueVariation,
                variation,
                base,
                waveColor,
                end
            )
        );
    }
}