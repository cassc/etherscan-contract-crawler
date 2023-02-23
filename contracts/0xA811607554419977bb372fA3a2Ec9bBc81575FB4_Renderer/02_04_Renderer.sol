//SPDX-License-Identifier: MIT

/*                                                                                                                                                                                                                                                                                                                                                                                                      
                             ,,,,,,,,,,,,,,,,,,,,,,,                            
                          ,,,%%%%%%%%%%%%%%%%%%%%%%%,,,                         
                    ,,,,,,%%%%%%                 %%%%%%,,,,,                    
                    ,,,,,,%%%%%%                 %%%%%%,,,,,                    
                    ,,,%%%                             %%/,,                    
                 .,,%%%                                  *%%,,,                 
               ,,/%%%%%                                  *%%%%%,,,              
               ,,/%%                                        %%%,,,              
               ,,/%%                                        %%%,,,              
               ,,/%%                                        %%%,,,              
               ,,/%%                                        %%%,,,              
               ,,/%%                                        %%%,,,              
               ,,/%%                                        %%%,,,              
               ,,/%%                                        %%%,,,              
               ,,/%%%%%                                  *%%%%%,,,              
                 .,,%%%                                  *%%,,,                 
                    ,,,%%%                             %%/,,                    
                    ,,,,,,%%%%%%                 %%%%%%,,,,,                    
                          ,,,%%%%%%%%%%%%%%%%%%%%%%%,,,                         
                          ,,,%%%%%%%%%%%%%%%%%%%%%%%,,,                         
                             ,,,,,,,,,,,,,,,,,,,,,,,                                                                                                                                                                                                                                                                                                                                                                          
*/
pragma solidity ^0.8.12;

import "./Utilities.sol";
import "./interfaces/BlackHole.sol";
import "hardhat/console.sol";

contract Renderer {
  uint256 public constant PIXELS_PER_SIDE = 28;
  uint256 constant PIXEL_SIZE = 10;
  uint256 constant CANVAS_SIZE = PIXELS_PER_SIDE * PIXEL_SIZE;

  string constant SPECIAL_STRING =
    '<g id="special"><path d="M120 0h10v10h-10V0Z" class="pixel-3"/><path d="M110 0h10v10h-10z" class="pixel-2"/><path d="M130 10h10v10h-10V10Zm-40 0H0v10h90V10Z" class="pixel-3"/><path d="M140 20H0v10h140z" class="pixel-1"/><path d="M40 40H0v10h40V40Z" class="pixel-3"/><path d="M70 30H0v10h70zm40-20h20v10h-20z" class="pixel-2"/><path d="M90 20h20V10H90v10Z" class="pixel-1"/><path d="M130 30H70v10h60V30Z" class="pixel-3"/></g>';

  bytes constant COLOR_SCHEMES =
    hex"02305a05000f05a03700005a01402d05a05001905a03700505a01403705a05002305a03700f05a01410e05a0500fa05a0370e605a01410d0640590fa0560530e603d0180";

  constructor() {}

  function getPixelSVG(
    uint256 pixelClass,
    uint8 x,
    uint8 y
  ) internal pure returns (string memory) {
    string memory class = string.concat("pixel-", utils.uint2str(pixelClass));
    return
      string(
        abi.encodePacked(
          '<rect x="',
          utils.uint2str(x * PIXEL_SIZE),
          '" y="',
          utils.uint2str(y * PIXEL_SIZE),
          '" width="',
          utils.uint2str(PIXEL_SIZE),
          '" height="',
          utils.uint2str(PIXEL_SIZE),
          '" class="',
          class,
          '"/>'
        )
      );
  }

  function getColorStyleDefinitions(BlackHole memory _blackHole) internal pure returns (string memory) {
    uint256 encoded;

    uint256 level = _blackHole.level;

    if (level <= 1) {
      encoded = utils.sliceUint(COLOR_SCHEMES, 0);
    } else if (level <= 3) {
      encoded = utils.sliceUint(COLOR_SCHEMES, 27);
    } else if (level <= 4) {
      encoded = utils.sliceUint(COLOR_SCHEMES, 36);
    }

    if (level == 4) {
      encoded = encoded >> 4;
    } else if (level % 2 == 0) {
      encoded = encoded >> 148;
    } else {
      encoded = encoded >> 40;
    }

    string memory style = "";
    for (uint256 i = 0; i < 4; i++) {
      string memory fillColor = "black";
      if (i > 0) {
        uint256 hslPacked = (encoded >> (72 - 12 * 3 * (i - 1))); // first color, next 3 nibbles is next color
        uint256[3] memory hsl = utils.unpackHsl(hslPacked);
        // hsl[0] -= _blackHole.adjustment;
        if (hsl[0] < _blackHole.adjustment) {
          hsl[0] = 360 - (_blackHole.adjustment - hsl[0]);
        } else {
          hsl[0] -= _blackHole.adjustment;
        }
        hsl[1] -= _blackHole.adjustment * 2;
        fillColor = utils.getHslString(hsl);
      }

      style = string.concat(style, ".pixel-", utils.uint2str(i), " {fill:", fillColor, ";} ");
    }

    return style;
  }

  struct QuarterCanvasVariables {
    uint256 renderEndIndex;
    uint256 renderStartIndex;
  }

  function getQuarterCanvas(BlackHole memory _blackHole) internal pure returns (string memory) {
    QuarterCanvasVariables memory vars;

    string memory edgeSVG = "";
    vars.renderEndIndex = PIXELS_PER_SIDE / 2;
    vars.renderStartIndex = vars.renderEndIndex - _blackHole.size - 5;
    for (uint256 i = vars.renderStartIndex; i <= vars.renderEndIndex; i++) {
      for (uint256 j = vars.renderStartIndex; j <= vars.renderEndIndex; j++) {
        int256 x = int256(j) - int256(PIXELS_PER_SIDE) / 2;
        int256 y = int256(i) - int256(PIXELS_PER_SIDE) / 2;
        uint256 distance = uint256(utils.sqrt(uint256(x * x) + uint256(y * y)));

        int256 classIndex = int256(distance) - int256(_blackHole.size);

        if (distance > _blackHole.size && distance <= _blackHole.size + 3) {
          edgeSVG = string.concat(edgeSVG, getPixelSVG(uint256(classIndex), uint8(j), uint8(i)));
        }
      }
    }

    return edgeSVG;
  }

  function getAnimatedStars(BlackHole memory _blackHole) internal pure returns (string memory) {
    string memory svg = "";

    for (uint256 i = 0; i < 10; i++) {
      // x is a random number from -PIXELS_PER_SIDE to 2*PIXELS_PER_SIDE
      uint256 x = utils.randomRange(
        _blackHole.tokenId,
        string.concat("animatedStarX", utils.uint2str(i)),
        0,
        PIXELS_PER_SIDE * 3
      );

      uint256 radius = _blackHole.size + 6;
      int256 discriminant = int256(radius) *
        int256(radius) -
        (int256(x) - int256(PIXELS_PER_SIDE) / 2) *
        (int256(x) - int256(PIXELS_PER_SIDE) / 2);
      uint256 minY = 0;
      uint256 maxY = PIXELS_PER_SIDE * 2;
      if (discriminant > 0) {
        // Bottom edge to bottom canvas
        minY = utils.sqrt(uint256(discriminant)) + PIXELS_PER_SIDE / 2;
        maxY = PIXELS_PER_SIDE * 2;

        // Top canvas to top edge
        if (utils.randomRange(_blackHole.tokenId, string.concat("animatedStarY", utils.uint2str(i)), 0, 2) == 1) {
          maxY = PIXELS_PER_SIDE - minY;
          minY = 0;
        }
      }

      // Select a random value between minY and maxY
      x = x * PIXEL_SIZE;
      uint256 y = utils.randomRange(_blackHole.tokenId, string.concat("animatedStarY", utils.uint2str(i)), minY, maxY) *
        PIXEL_SIZE;

      uint256 fillLightness = utils.randomRange(
        _blackHole.tokenId,
        string.concat("fillLightness", utils.uint2str(i)),
        15,
        200
      );
      string memory fillColor = utils.getHslString([0, 0, fillLightness]);

      uint256 animateDuration = 2;
      uint256 animationOffset = utils.randomRange(
        _blackHole.tokenId,
        string.concat("animationOffset", utils.uint2str(i)),
        0,
        2000
      );

      string memory animationCommon = string.concat(
        'dur="',
        utils.uint2str(animateDuration),
        's" repeatCount="indefinite" begin="',
        utils.uint2floatstr(animationOffset, 3),
        's" calcMode="spline" keyTimes="0;1" keySplines="0.4,0,0.2,1"'
      );

      string memory transformAnimation = string.concat(
        '<animate attributeName="x" from="',
        utils.uint2str(x),
        '" to="',
        utils.uint2str((PIXELS_PER_SIDE * PIXEL_SIZE) / 2),
        '" values="',
        utils.uint2str(x),
        ";",
        utils.uint2str((PIXELS_PER_SIDE * PIXEL_SIZE) / 2),
        '" ',
        animationCommon,
        "/>"
      );

      transformAnimation = string.concat(
        transformAnimation,
        '<animate attributeName="y" from="',
        utils.uint2str(y),
        '" to="',
        utils.uint2str((PIXELS_PER_SIDE * PIXEL_SIZE) / 2),
        '" values="',
        utils.uint2str(y),
        ";",
        utils.uint2str((PIXELS_PER_SIDE * PIXEL_SIZE) / 2),
        '" ',
        animationCommon,
        "/>"
      );

      transformAnimation = string.concat(
        transformAnimation,
        '<animate attributeName="fill-opacity" from="1" to="0" values="1;0" ',
        animationCommon,
        "/>"
      );

      string memory pixel = string.concat(
        '<rect x="',
        utils.uint2str(x),
        '" y="',
        utils.uint2str(y),
        '" width="',
        utils.uint2str(PIXEL_SIZE),
        '" height="',
        utils.uint2str(PIXEL_SIZE),
        '" fill="',
        fillColor,
        '">',
        transformAnimation,
        "</rect>"
      );

      svg = string.concat(svg, pixel);
    }
    return svg;
  }

  function getStaticBackground(BlackHole memory _blackHole) internal pure returns (string memory) {
    string memory svg = "";
    for (uint256 i = 0; i < 30; i++) {
      uint256 x = utils.randomRange(
        _blackHole.tokenId,
        string.concat("staticX", utils.uint2str(i)),
        0,
        PIXELS_PER_SIDE
      ) * PIXEL_SIZE;
      uint256 y = utils.randomRange(
        _blackHole.tokenId,
        string.concat("staticY", utils.uint2str(i)),
        0,
        PIXELS_PER_SIDE
      ) * PIXEL_SIZE;

      uint256 fillLightness = utils.randomRange(
        _blackHole.tokenId,
        string.concat("fillLightness", utils.uint2str(i)),
        5,
        12
      );
      string memory fillColor = utils.getHslString([0, 0, fillLightness]);

      string memory pixel = string.concat(
        '<rect x="',
        utils.uint2str(x),
        '" y="',
        utils.uint2str(y),
        '" width="',
        utils.uint2str(PIXEL_SIZE),
        '" height="',
        utils.uint2str(PIXEL_SIZE),
        '" fill="',
        fillColor,
        '"/>'
      );

      svg = string.concat(svg, pixel);
    }
    return svg;
  }

  function getBlackHoleSVG(BlackHole memory _blackHole) public pure returns (string memory) {
    string memory svg = string.concat(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ',
      utils.uint2str(CANVAS_SIZE),
      " ",
      utils.uint2str(CANVAS_SIZE),
      '" width="500" height="500">'
    );

    // -- defs
    // Style
    string memory colorsStyle = getColorStyleDefinitions(_blackHole);
    string memory style = string.concat("<style>", colorsStyle, "</style>");
    svg = string.concat(svg, "<defs>", style);

    // Edge def
    string memory edgeSvg = getQuarterCanvas(_blackHole);
    string memory g = string.concat('<g id="edge">', edgeSvg, "</g>");
    svg = string.concat(svg, '<g id="full">', g);
    svg = string.concat(
      svg,
      '<use href="#edge" transform="scale(-1,1),translate(-',
      utils.uint2str(CANVAS_SIZE),
      ',0)" />'
    );
    svg = string.concat(
      svg,
      '<use href="#edge" transform="scale(1,-1),translate(0,-',
      utils.uint2str(CANVAS_SIZE),
      ')" />'
    );
    svg = string.concat(
      svg,
      '<use href="#edge" transform="scale(-1,-1),translate(-',
      utils.uint2str(CANVAS_SIZE),
      ",-",
      utils.uint2str(CANVAS_SIZE),
      ')" /></g>'
    );

    // Special string def
    if (_blackHole.level == 4) svg = string.concat(svg, SPECIAL_STRING);

    // -- end defs
    svg = string.concat(svg, "</defs>");

    // Black background
    svg = string.concat(
      svg,
      '<rect x="0" y="0" width="',
      utils.uint2str(CANVAS_SIZE),
      '" height="',
      utils.uint2str(CANVAS_SIZE),
      '" fill="black"/>'
    );

    // Static background
    svg = string.concat(svg, '<g id="background">', getStaticBackground(_blackHole), "</g>");

    // Black background part of black hole
    uint256 backgroundOffset = CANVAS_SIZE / 2 - _blackHole.size * PIXEL_SIZE;
    uint256 backgroundSize = 2 * _blackHole.size * PIXEL_SIZE;
    svg = string.concat(
      svg,
      '<rect fill="black" x="',
      utils.uint2str(backgroundOffset),
      '" y="',
      utils.uint2str(backgroundOffset),
      '" width="',
      utils.uint2str(backgroundSize),
      '"  height="',
      utils.uint2str(backgroundSize),
      '" />'
    );

    // Edge part
    svg = string.concat(svg, '<use href="#full" />');

    // Animated stars
    // svg += getAnimatedStars(holeSize, level)
    svg = string.concat(svg, getAnimatedStars(_blackHole));

    // Special string
    if (_blackHole.level == 4) {
      svg = string.concat(
        svg,
        '<use href="#special" transform="translate(',
        utils.uint2str(CANVAS_SIZE / 2 - PIXEL_SIZE),
        ",",
        utils.uint2str(CANVAS_SIZE / 2),
        ')" />',
        '<use href="#special" transform="scale(-1,1),translate(-',
        utils.uint2str(CANVAS_SIZE / 2 + PIXEL_SIZE),
        ",",
        utils.uint2str(CANVAS_SIZE / 2),
        ')" />'
      );
    }

    svg = string.concat(svg, "</svg>");

    return svg;
  }

  function renderSample(uint256 tokenId, uint256 level) external pure returns (string memory) {
    uint256 size = PIXELS_PER_SIDE / 2 - (10 - level); // 5
    BlackHole memory blackHole = BlackHole({
      tokenId: tokenId,
      level: level,
      size: size,
      mass: 1,
      adjustment: 15,
      name: "Micro"
    });
    return getBlackHoleSVG(blackHole);
  }
}