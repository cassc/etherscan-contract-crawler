//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./interfaces/IPlanets.sol";
import "./Utilities.sol";

contract PlanetsThumbnail {
  uint256 private constant CANVAS_SIZE = 500;
  bytes private constant BACKGROUND =
    '<g fill="#fff"><circle cx="50" cy="100" r="2" fill="#fff"/><circle cx="200" cy="150" r="2" fill="#fff"/><circle cx="300" cy="250" r="2" fill="#fff"/><circle cx="400" cy="75" r="2" fill="#fff"/><circle cx="175" cy="200" r="2" fill="#fff"/><circle cx="450" cy="350" r="2" fill="#fff"/><circle cx="125" cy="400" r="2" fill="#fff"/><circle cx="375" cy="300" r="2" fill="#fff"/><circle cx="225" cy="375" r="2" fill="#fff"/><circle cx="75" cy="250" r="2" fill="#fff"/><circle cx="25" cy="25" r="2" fill="#fff"/></g>';
  bytes private constant PLANET =
    '<path class="rings" stroke-width="8.686" d="M149.379 79.264c0-5.756-32.406-10.423-72.38-10.423-39.976 0-72.382 4.667-72.382 10.423"/><ellipse cx="76.713" cy="69.999" class="body" rx="50.088" ry="49.798"/><mask id="a" width="101" height="102" x="26" y="19" maskUnits="userSpaceOnUse" style="mask-type:alpha"><circle cx="76.515" cy="70" r="50" fill="#AC0000" transform="rotate(-33.909 76.515 70)"/></mask><g mask="url(#a)"><path class="water" d="M84.845 48.333c.476-2.063 2.428-8.047 6.428-15.476 3.049-1.905 10.795-3.016 14.287-3.333h14.048l15 25-8.81 24.285h-.714c-.571.572-2.143.556-2.857.477l-9.762-5.477a20.235 20.235 0 0 0-21.192-12.857c-12.952 1.143-9.682-7.936-6.428-12.619ZM34.137 66.904c-3.239-1.333-6.27 2.46-7.381 4.524l-2.858 1.429 2.143 23.095 25.477 20.953c1.587-1.826 5-6.381 5.952-10 1.19-4.524-3.333-7.858-6.905-9.286-3.571-1.429-1.905-8.572-.714-11.429 1.19-2.857-3.334-8.571-8.334-11.428-5-2.858-3.333-6.19-7.38-7.858Z"/><path class="body-sec" d="M72.5 100.5C67 93.5 80 89.5 78 84c1.334-1.167 5.2-4.4 10-8 6-4.5 19.5 0 23 4.5s-.5 11-3.5 20c-2.4 7.2-10 8-13.5 7.5-5.333-.167-17.1-1.9-21.5-7.5ZM44 70.5c0-2-2.6-8.2-13-17l-4.5-2 20-25.5c2.167 1.833 7.3 4.4 10.5 0 4-5.5 10.5.5 13 5.5S61.5 41 70 42s8 1 8 11.5S72.5 57 72.5 65s-9 11-17 11c-6.4 0-10.333-3.667-11.5-5.5Z"/></g><path class="rings" stroke-width="8.686" d="M149.379 78.106c0 5.757-32.406 10.423-72.38 10.423-39.976 0-72.382-4.666-72.382-10.423"/>';

  string[3] private MOONS = [
    '<circle cx="22" cy="171" r="22" fill="#BBBBBB"/>',
    '<circle cx="370" cy="106" r="16" fill="#BBBBBB"/>',
    '<circle cx="30" cy="11" r="11" fill="#BBBBBB"/>'
  ];

  function getPlanet(uint256 planetSize) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          '<g transform-origin="72 60" transform="translate(-26,-20),translate(200,200),scale(',
          utils.uint2floatstr((planetSize * 1e3) / 40, 3),
          ')">',
          PLANET,
          "</g>"
        )
      );
  }

  function getMoons(uint256 numMoons) internal view returns (bytes memory) {
    bytes memory moons = '<g transform="translate(50,170)">';
    for (uint256 i = 0; i < numMoons; i++) {
      moons = abi.encodePacked(moons, MOONS[i]);
    }
    moons = abi.encodePacked(moons, "</g>");
    return moons;
  }

  /**
   * @notice Build the SVG thumbnail
   * @param _settings - Track settings struct
   * @return final svg as bytes
   */
  function buildThumbnail(Settings calldata _settings) external view returns (bytes memory) {
    bytes memory svg = abi.encodePacked(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ',
      utils.uint2str(CANVAS_SIZE),
      " ",
      utils.uint2str(CANVAS_SIZE),
      '" width="500" height="500" fill="none">',
      // "<defs><style>.rings{stroke:",
      // _settings.hasRings ? getHSL(_settings.hue, 100, 15) : "none",
      // ";}.body{fill:",
      // getHSL(_settings.hue, 70, 34),
      // ";}.water{fill:",
      // _settings.planetType == PlanetType.SOLID ? "#2680D9" : "none",
      // ";}</style></defs>",
      "<defs><style>",
      ".rings { stroke: ",
      _settings.hasRings ? utils.getHSL(_settings.hue, 100, 15) : "none",
      "; }",
      ".body { fill: ",
      utils.getHSL(_settings.hue, 60, 40),
      "; }",
      ".body-sec { fill: ",
      _settings.planetType == PlanetType.SOLID ? utils.getHSL((_settings.hue + 5) % 360, 45, 50) : "none",
      "; }",
      ".water { fill: ",
      _settings.hasWater ? "#2680D9" : "none",
      "; }",
      "</style></defs>",
      '<rect x="0" y="0" width="',
      utils.uint2str(CANVAS_SIZE),
      '" height="',
      utils.uint2str(CANVAS_SIZE),
      '" fill="#000000"/>',
      BACKGROUND,
      getPlanet(_settings.planetSize),
      getMoons(_settings.numMoons),
      '<g transform="translate(440,470)"><text x="13" y="0" fill="#fff" font-size="24" font-family="Helvetica">2D</text><text x="13" y="15" fill="#fff" font-size="12" font-family="Helvetica">VIEW</text></g></svg>'
    );

    return svg;
  }
}