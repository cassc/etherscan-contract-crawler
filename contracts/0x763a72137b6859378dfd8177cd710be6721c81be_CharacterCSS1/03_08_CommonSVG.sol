// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./Environment.sol";
import "./Patterns.sol";
import "./GridHelper.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library CommonSVG {

  // opening svg start tag
  string internal constant SVG_START = "<svg xmlns='http://www.w3.org/2000/svg' shape-rendering='geometricPrecision' text-rendering='geometricPrecision' width='936' height='1080' xmlns:xlink='http://www.w3.org/1999/xlink'>";

  string internal constant DUOTONE_DEFS = "<linearGradient id='lDT' gradientTransform='rotate(45)'><stop offset='0.2' stop-color='hsla(0, 0%, 0%, 0)'></stop><stop offset='1' stop-color='hsla(0, 0%, 0%, 0.2)'></stop></linearGradient><linearGradient id='rDT' gradientTransform='rotate(0)'><stop offset='0.2' stop-color='hsla(0, 0%, 0%, 0)'></stop><stop offset='1' stop-color='hsla(0, 0%, 0%, 0.2)'></stop></linearGradient><linearGradient id='fDT' gradientTransform='rotate(90)'><stop offset='0' stop-color='hsla(0, 0%, 0%, 0)'></stop><stop offset='1' stop-color='hsla(0, 0%, 0%, 0.2)'></stop></linearGradient>";

  string internal constant SCRIPT = "<script type='text/javascript' href='https://demowebdevukssa2.z33.web.core.windows.net/html-svg/pocs/0311/anma.js' xlink:actuate='onLoad' xlink:show='other' xlink:type='simple' />";
  // string internal constant SCRIPT = "";

  string internal constant STYLE = "<style>";

  string internal constant TEMP_STYLE = "<style> .no-animation * { animation: none !important; transition: none !important; } </style>";

  string internal constant STYLE_CLOSE = "</style>";

  string internal constant G_START = "<g>";

  string internal constant FLIPPED = "<g style='transform:scaleX(-1);transform-origin:50% 50%;'>";

  string internal constant NOT_FLIPPED = "<g style='transform:scaleX(1);transform-origin:50% 50%;'>";

  string internal constant SHELL_OPEN = "<g style='transform:scaleX(";

  string internal constant SHELL_CLOSE = ");transform-origin:50% 50%;' id='shell' clip-path='url(#clipPathShell)' ";

  string internal constant ROTATIONS = "-40-45-45";

  // 18 colours: light, base and dark for each of the 6 gradients
  string internal constant OBJECT_GRADIENTS_IDS = "c0lc0bc0dc1lc1bc1dc2lc2bc2dc3lc3bc3dc4lc4bc4dc5lc5bc5d";

  string internal constant LIGHTEN_PERCENTAGES = "025000025"; // 25% lighter, 0% base, 25% darker

  string internal constant GRADIENT_STYLE_OPEN = "<style id='gradient-colors'> :root { ";

  string internal constant GRADIENT_STYLE_CLOSE = " } </style>";

  string internal constant GLOBAL_COLOURS = "051093072042080068328072085327073074027087076025054060000000069000000050085092060082067051051093072060088081002087076000054060000000069000000050322092060322092056322092060322092056047084056046068047000000069000000050";

  string internal constant GLOBAL_COLOURS_IDS = "g0g1g2g3g4g5g6g7";

  string internal constant SHELL_COLOUR_IDS = "s2s1s0";

  string internal constant CHARACTER_COLOUR_IDS = "r0";

  // string internal constant x = "<g id='shell-vignette' style='mix-blend-mode:normal'><rect fill='url(#vig1-u-vig1-fill)' width='1080' height='1080'/></g>";
  string internal constant VIGNETTE_GRADIENT = "<clipPath id='clipPathShell'><polygon points='0,270 468,0 936,270 936,810 468,1080 0,810'/></clipPath><radialGradient id='vig1-u-vig1-fill' cx='0' cy='0' r='0.5' spreadMethod='pad' gradientUnits='objectBoundingBox' gradientTransform='translate(0.43 0.5)'><stop id='vig1-u-vig1-fill-0' offset='50%' stop-color='#000' stop-opacity='0'/><stop id='vig1-u-vig1-fill-1' offset='100%' stop-color='#000' stop-opacity='0.3'/></radialGradient>";

  // PATTERNS
  string internal constant PATTERNS_START = "<pattern id='shell-pattern' patternUnits='objectBoundingBox' x='0' y='0' width='";

  string internal constant PATTERNS_HEIGHT = "' height='";

  string internal constant PATTERNS_SCALE_OPEN = "' patternTransform=' scale(";

  string internal constant PATTERNS_SCALE_CLOSE = ")'><use xmlns:xlink='http://www.w3.org/1999/xlink' xlink:href='#mp2-u-group-";

  string internal constant PATTERNS_END = "' id='shell-pattern-use' class='pulsateInOutOld'/></pattern>";

  string internal constant OPACITY_START = "<g id='leftWall'><polygon points='0,270 468,0 468,540 0,810' fill='url(#s0)' stroke='black'/><g id='leftWallPat' transform='skewY(-30)'><rect x='0' y='270' width='468' height='540' opacity='";

  string internal constant OPACITY_MID_ONE = "%' style='mix-blend-mode: normal;' fill='url(#shell-pattern)'/></g><polygon points='0,270 468,0 468,540 0,810' fill='url(#lDT)' stroke='black'/></g><g id='rightWall'><polygon points='468,540 468,0 936,270 936,810' fill='url(#s1)' stroke='black'/><g id='rightWallPat' transform='skewY(30)'><rect x='468' y='-270' width='468' height='540' opacity='";

  string internal constant OPACITY_MID_TWO = "%' style='mix-blend-mode: normal;' fill='url(#shell-pattern)'/></g><polygon points='468,540 468,0 936,270 936,810' fill='url(#rDT)' stroke='black'/></g><g id='floor'><polygon id='polygon-floor-border' points='0,810 468,1080 936,810 468,540' fill='url(#s2)' stroke='black'/><g id='floorPat' transform='translate(234 135) rotate(60)' transform-origin='0 540'><g transform='skewY(-30)' transform-origin='0 0'><rect id='floorPatRect' x='0' y='270' width='468' height='540' opacity='";

  string internal constant OPACITY_END = "%' style='mix-blend-mode: normal;' fill='url(#shell-pattern)'/></g></g><polygon id='polygon-floor-border-DT' points='0,810 468,1080 936,810 468,540' fill='url(#fDT)' stroke='black'/></g>";

  function createObjectGradient(uint[6] memory colours, string memory id) internal pure returns (string memory) {
    string memory output = string.concat(
      "<linearGradient id='",
      id,
      "' x1='0%' y1='0%' x2='100%' y2='0%'><stop offset='0%' stop-color='hsl(",
      Strings.toString(colours[0]),
      ",",
      Strings.toString(colours[1]),
      "%,"
    );

    output = string.concat(
      output,
      Strings.toString(colours[2]),
      "%)'/><stop offset='100%' stop-color='hsl(",
      Strings.toString(colours[3]),
      ",",
      Strings.toString(colours[4]),
      "%,",
      Strings.toString(colours[5]),
      "%)'/></linearGradient>"
    );

    return output;
  }

  function appendToGradientStyle(string memory gradientStyle, string memory id, uint h, uint s, uint l) internal pure returns (string memory) {
    return string.concat(
      gradientStyle,
      "--",
      id,
      ": hsl(",
      Strings.toString(h),
      ",",
      Strings.toString(s),
      "%,",
      Strings.toString(l),
      "%); "
    );
  }

  function getshellColours(string memory machine, uint colourValue) external pure returns(string memory) {
    uint[] memory baseColours = Environment.getColours(machine, colourValue); // 12 colours, 3 values for each

    string memory gradientStyle = GRADIENT_STYLE_OPEN;
    // uint[] memory lightenBy = GridHelper.setUintArrayFromString(LIGHTEN_PERCENTAGES, 3, 3);
    string[] memory objectGradients = new string[](18);
    for (uint i = 0; i < 6; ++i) {
      for (uint j = 0; j < 3; ++j) {
        objectGradients[i*3+j] = createObjectGradient([baseColours[i*6], baseColours[i*6+1], baseColours[i*6+2], baseColours[i*6+3], baseColours[i*6+4], baseColours[i*6+5]], string(GridHelper.slice(bytes(OBJECT_GRADIENTS_IDS), i*9+3*j, 3)));
        if (j == 1) {
          gradientStyle = appendToGradientStyle(gradientStyle, string(GridHelper.slice(bytes(OBJECT_GRADIENTS_IDS), i*9+3*j, 3)), baseColours[i*6], baseColours[i*6+1], baseColours[i*6+2]);
        } else {
          gradientStyle = appendToGradientStyle(gradientStyle, string(GridHelper.slice(bytes(OBJECT_GRADIENTS_IDS), i*9+3*j, 3)), baseColours[i*6+3], baseColours[i*6+4], baseColours[i*6+5]);
        }
      }
    }

    // SHELL COLOURS
    string[] memory shellColours = new string[](3);
    for (uint i = 0; i < 3; ++i) {
      shellColours[i] = createObjectGradient([baseColours[i*6], baseColours[i*6+1], baseColours[i*6+2], baseColours[i*6+3], baseColours[i*6+4], baseColours[i*6+5]], string(GridHelper.slice(bytes(SHELL_COLOUR_IDS), i*2, 2)));
    }

    // GLOBAL COLOURS
    uint[] memory globalColours = GridHelper.setUintArrayFromString(GLOBAL_COLOURS, 72, 3);
    uint globalOffset = 0;
    if (colourValue > 170) {
      globalOffset = 48;
    } else if (colourValue > 84) {
      globalOffset = 24;
    }
    for (uint i = 0; i < 8; ++i) {
      gradientStyle = appendToGradientStyle(gradientStyle, string(GridHelper.slice(bytes(GLOBAL_COLOURS_IDS), i*2, 2)), globalColours[i*3+globalOffset], globalColours[i*3+1+globalOffset], globalColours[i*3+2+globalOffset]);
    }

    // CHARACTER COLOURs
    gradientStyle = appendToGradientStyle(gradientStyle, string(GridHelper.slice(bytes(CHARACTER_COLOUR_IDS), 0, 2)), baseColours[0], baseColours[1], 90);

    gradientStyle = string.concat(gradientStyle, GRADIENT_STYLE_CLOSE);

    string memory returnDefs = string.concat(
      gradientStyle,
      "<defs>",
      VIGNETTE_GRADIENT,
      DUOTONE_DEFS
    );

    for (uint i = 0; i < 18; ++i) {
      returnDefs = string.concat(returnDefs, objectGradients[i]);
    }

    for (uint i = 0; i < 3; ++i) {
      returnDefs = string.concat(returnDefs, shellColours[i]);
    }

    returnDefs = string.concat(returnDefs, "</defs>");

    return returnDefs;
  }

  function createShellPattern(uint rand, int baseline) external pure returns(string memory) {
    return string.concat(
      PATTERNS_START,
      "0.330", // width
      PATTERNS_HEIGHT,
      "0.330", // height
      PATTERNS_SCALE_OPEN,
      Patterns.getScale(rand, baseline),
      PATTERNS_SCALE_CLOSE,
      Patterns.getPatternName(rand, baseline),
      PATTERNS_END
    );
  }

  function createShellOpacity(uint rand, int baseline) external pure returns(string memory) {
    return string.concat(
      OPACITY_START,
      Patterns.getOpacity(rand, baseline, 0),
      OPACITY_MID_ONE,
      Patterns.getOpacity(rand, baseline, 1),
      OPACITY_MID_TWO,
      Patterns.getOpacity(rand, baseline, 2),
      OPACITY_END
    );
  }
}