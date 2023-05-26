//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Trigonometry.sol";
import "./Utilities.sol";

contract Renderer {
  uint256 constant SIZE = 500;

  struct Planet {
    uint256 planetRadius;
    uint256 ringsOffset;
    uint256 orbitRadius;
    uint256[3] color;
    uint256 initialAngleDegrees;
    uint256 duration;
  }

  function translateWithAngle(
    int256 x,
    int256 y,
    uint256 degrees
  ) internal pure returns (int256, int256) {
    int256 newX = x;
    int256 newY = y;

    newX =
      x *
      Trigonometry.cos(degrees * (Trigonometry.PI / 180)) -
      y *
      Trigonometry.sin(degrees * (Trigonometry.PI / 180));
    newY =
      x *
      Trigonometry.sin(degrees * (Trigonometry.PI / 180)) +
      y *
      Trigonometry.cos(degrees * (Trigonometry.PI / 180));

    return (newX, newY);
  }


  /**
  * @notice Gets the SVG representation of a planet's orbit.
  * @param planet The planet to generate the SVG for.
  */
  function getOrbitSVG(Planet memory planet) public pure returns (string memory) {
    uint256 halfCanvasWidth = SIZE / 2;

    // Calculate the initial position of the planet
    int256 x = int256(planet.orbitRadius);
    int256 y = 0;

    (int256 innerX, int256 innerY) = translateWithAngle(x - 1, y, planet.initialAngleDegrees);
    (int256 outerX, int256 outerY) = translateWithAngle(x, y, planet.initialAngleDegrees);

    string memory colorTuple = string.concat(
      utils.uint2str(planet.color[0]),
      ",",
      utils.uint2str(planet.color[1]),
      ",",
      utils.uint2str(planet.color[2])
    );

    // Generate the SVG string
    string memory renderedSVG = string.concat(
      '<circle cx="',
      utils.uint2str(halfCanvasWidth),
      '" cy="',
      utils.uint2str(halfCanvasWidth),
      '" r="',
       utils.uint2str(planet.orbitRadius),
      '" fill="none" stroke="rgba(',
      colorTuple,
      ',0.5)"/>',
      // Inner circle
      '<g><circle cx="',
      utils.uint2str(uint256(int256(halfCanvasWidth) + innerX / 1e18)),
      '" cy="'
      
    );

    renderedSVG = string.concat(
      renderedSVG,
      utils.uint2str(uint256(int256(halfCanvasWidth) - innerY / 1e18)),
      '" r="',
      utils.uint2str(planet.planetRadius - 2),
      '" fill="rgb(',
      colorTuple,
      ')"/>'
      // Outer circle
      '<circle cx="',
      utils.uint2str(uint256(int256(halfCanvasWidth) + outerX / 1e18)),
      '" cy="'
    );

    renderedSVG = string.concat(
      renderedSVG,
      utils.uint2str(uint256(int256(halfCanvasWidth) - outerY / 1e18)),
      '" r="',
      utils.uint2str(planet.planetRadius),
      '" fill-opacity="0.8" fill="rgb(',
      colorTuple,
      ')"/>'
    );

    if (planet.ringsOffset != 0) {
      uint256 ringsRadius = planet.planetRadius + planet.ringsOffset;
      renderedSVG = string.concat(
        renderedSVG,
        // Rings
        '<circle cx="',
        utils.uint2str(uint256(int256(halfCanvasWidth) + outerX / 1e18)),
        '" cy="',
        utils.uint2str(uint256(int256(halfCanvasWidth) - outerY / 1e18)),
        '" r="',
        utils.uint2str(ringsRadius),
        '" fill="none" stroke-width="1" stroke="rgb(',
        colorTuple,
        ')"/>'
      );
    }

    renderedSVG = string.concat(
      renderedSVG,
      '<animateTransform attributeName="transform" type="rotate" from="0 ',
      utils.uint2str(halfCanvasWidth),
      " ",
      utils.uint2str(halfCanvasWidth),
      '" to="360 ',
      utils.uint2str(halfCanvasWidth),
      " ",
      utils.uint2str(halfCanvasWidth),
      '" dur="'
    );

    renderedSVG = string.concat(
      renderedSVG,
      utils.uint2str(planet.duration),
      's" repeatCount="indefinite"></animateTransform>',
      "</g>"
    );

    return renderedSVG;
  }

  /**
  * @notice Gets the number of planets in a solar system.
  * @param _tokenId The token ID of the solar system to get the number of planets for.
  */
  function numPlanetsForTokenId(uint256 _tokenId) public pure returns (uint256) {
    return utils.randomRange(_tokenId, "numPlanets", 1, 6);
  }

  /**
  * @notice Gets the number of ringed planets in a solar system.
  * @param _tokenId The token ID of the solar system to get the number of ringed planets for.
  */
  function numRingedPlanetsForTokenId(uint256 _tokenId) public pure returns (uint256) {
    uint256 numRingedPlanets;
    for (uint256 i = 0; i < numPlanetsForTokenId(_tokenId); i++) {
      if (utils.randomRange(_tokenId, string.concat("ringsOffset", utils.uint2str(i)), 0, 10) == 5) {
        numRingedPlanets++;
      }
    }
    return numRingedPlanets;
  }

  /**
  * @notice Determines if a solar system has a rare star.
  * @param _tokenId The token ID of the solar system to check.
  */
  function hasRareStarForTokenId(uint256 _tokenId) public pure returns (bool) {
    return utils.randomRange(_tokenId, "rareStar", 0, 10) == 5;
  }

  /**
  * @notice Gets the SVG representation of a solar system.
  * @param _tokenId The token ID of the solar system to generate the SVG for.
  */
  function getSVG(uint256 _tokenId) public pure returns (string memory) {
    uint256 numPlanets = numPlanetsForTokenId(_tokenId);
    uint256 radiusInterval = SIZE / 2 / (numPlanets + 3);
    uint256 planetRadiusUpperBound = utils.min(radiusInterval / 2, SIZE / 4);
    uint256 planetRadiusLowerBound = radiusInterval / 4;

    uint256 starRadius = utils.randomRange(_tokenId, "starRadius", radiusInterval, radiusInterval * 2 - 10);
    string memory starAttributes = hasRareStarForTokenId(_tokenId) ? 'fill="#39B1FF"' : 'fill="#FFDA17"';

    string memory renderSvg = string.concat(
      '<svg width="',
      utils.uint2str(SIZE),
      '" height="',
      utils.uint2str(SIZE),
      '" viewBox="0 0 ',
      utils.uint2str(SIZE),
      " ",
      utils.uint2str(SIZE),
      '" xmlns="http://www.w3.org/2000/svg">',
      '<rect width="',
      utils.uint2str(SIZE),
      '" height="',
      utils.uint2str(SIZE),
      '" fill="#0D1F2F"></rect>',
      '<circle cx="',
      utils.uint2str(SIZE / 2),
      '" cy="',
      utils.uint2str(SIZE / 2),
      '" r="',
      utils.uint2str(starRadius),
      '" ',
      starAttributes,
      "/>"
    );

    for (uint256 i = 0; i < numPlanets; i++) {
      Planet memory planet;

      if (utils.randomRange(_tokenId, string.concat("ringsOffset", utils.uint2str(i)), 0, 10) == 5) {
        planet.ringsOffset = 4;
      }

      planet.planetRadius = utils.randomRange(
        _tokenId,
        string.concat("planetRadius", utils.uint2str(i)),
        planetRadiusLowerBound,
        planetRadiusUpperBound - planet.ringsOffset
      );

      planet.orbitRadius = radiusInterval * (i + 3);
      planet.duration = utils.randomRange(_tokenId, string.concat("duration", utils.uint2str(i)), 5, 15);

      planet.color[0] = utils.randomRange(_tokenId, string.concat("colorR", utils.uint2str(i)), 100, 255);
      planet.color[1] = utils.randomRange(_tokenId, string.concat("colorG", utils.uint2str(i)), 100, 255);
      planet.color[2] = utils.randomRange(_tokenId, string.concat("colorB", utils.uint2str(i)), 100, 255);

      planet.initialAngleDegrees = utils.randomRange(
        _tokenId,
        string.concat("initialAngle", utils.uint2str(i)),
        0,
        360
      );

      string memory planetSVG = getOrbitSVG(planet);
      renderSvg = string.concat(renderSvg, planetSVG);
    }

    renderSvg = string.concat(renderSvg, "</svg>");

    return renderSvg;
  }

  function render(uint256 _tokenId) public pure returns (string memory) {
    return getSVG(_tokenId);
  }
}