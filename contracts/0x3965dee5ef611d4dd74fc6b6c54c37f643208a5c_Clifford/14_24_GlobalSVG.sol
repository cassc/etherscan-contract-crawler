// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./CommonSVG.sol";

interface ILibrary {
  function getPart() external view returns (string memory);
}

contract GlobalSVG {
  constructor(address[13] memory allLibraries) {
    libraryDeployments = allLibraries;
  }

  address[13] public libraryDeployments;

  string internal constant TEXTURE_CSS_OPEN = ":root { --grey: hsl(0, 0%, 10%); --anim-speed: ";
  string internal constant TEXTURE_CSS_MID = "s; --rdm-seed: 0.";
  string internal constant TEXTURE_CSS_CLOSE = "; --anim-scale-0: 1; --anim-scale-50: 5; --anim-scale-100: 1; --end-rotation: calc(var(--rdm-seed) * 360); --num-rectangles: 7; } .pulsateInOutOld { animation: pulsateInOutOld var(--anim-speed) infinite linear; } @keyframes infinityWellRect { 0% { opacity: 0; transform: scale(1.1) rotate(0deg); transform-origin: 78px 90px; } 10% { opacity: 1; } 100% { opacity: 1; transform: scale(0) rotate(calc(var(--end-rotation) * 1deg)); transform-origin: 78px 90px; } } .infinityWell { animation: infinityWell var(--anim-speed) infinite linear forwards; } .infinityWellRect { animation: infinityWell var(--anim-speed) infinite linear forwards; } .rt-0 { animation: infinityWellRect var(--anim-speed) infinite linear; } .rt-1 { animation: infinityWellRect var(--anim-speed) infinite linear; animation-delay: calc(var(--anim-speed) / 8 * 1); } .rt-2 { animation: infinityWellRect var(--anim-speed) infinite linear; animation-delay: calc(var(--anim-speed) / 8 * 2); } .rt-3 { animation: infinityWellRect var(--anim-speed) infinite linear; animation-delay: calc(var(--anim-speed) / 8 * 3); } .rt-4 { animation: infinityWellRect var(--anim-speed) infinite linear; animation-delay: calc(var(--anim-speed) / 8 * 4); } .rt-5 { animation: infinityWellRect var(--anim-speed) infinite linear; animation-delay: calc(var(--anim-speed) / 8 * 5); } .rt-6 { animation: infinityWellRect var(--anim-speed) infinite linear; animation-delay: calc(var(--anim-speed) / 8 * 6); } .rt-7 { animation: infinityWellRect var(--anim-speed) infinite linear; animation-delay: calc(var(--anim-speed) / 8 * 7); } }";

  string internal constant PATTERN_CSS_OPEN = ":root { --anim-speed: ";
  string internal constant PATTERN_CSS_CLOSE = "s; --anim-scale-0: 1; --anim-scale-50: 2; --anim-scale-100: 1; } @keyframes pulsateInOutOld { 0% { transform: scale(var(--anim-scale-0)); transform-origin: 78px 90px; } 50% { transform: scale(var(--anim-scale-50)); transform-origin: 78px 90px; } 100% { transform: scale(var(--anim-scale-100)); transform-origin: 78px 90px; } } .pulsateInOutOld { animation: pulsateInOutOld var(--anim-speed) infinite linear; }";

  function getAnimationSpeed(int baseline) internal pure returns (string memory) {
    uint patternSpeed = 0;
    uint textureSpeed = uint(baseline) % 30;

    if (baseline > 185 || baseline < 70) {
      patternSpeed = 10 + uint(baseline) % 11;
    }

    if (baseline < 70) {
      return string.concat(
        TEXTURE_CSS_OPEN,
        Strings.toString(patternSpeed),
        TEXTURE_CSS_MID,
        Strings.toString(textureSpeed),
        TEXTURE_CSS_CLOSE
      );
    } else {
      return string.concat(
        PATTERN_CSS_OPEN,
        Strings.toString(patternSpeed),
        PATTERN_CSS_CLOSE
      );
    }
  }

  function getClosingSVG() external pure returns (string memory) {
    return string.concat(
      "<g id='shell-vignette' style='mix-blend-mode:normal'><rect fill='url(#vig1-u-vig1-fill)' width='1080' height='1080'/></g>",
      "</g>",
      "</svg>"
    );
  }

  function getShell(string memory flip, uint rand, int baseline, string memory dataInfo) external pure returns (string memory) {
    return string.concat(
      CommonSVG.SHELL_OPEN,
      flip,
      CommonSVG.SHELL_CLOSE,
      dataInfo,
      CommonSVG.createShellOpacity(rand, baseline)
    );
  }

  function getOpeningSVG(string memory machine, uint colourValue, uint rand, int baseline) external view returns (string memory) {

    string memory output = string.concat(
      CommonSVG.SVG_START,
      CommonSVG.getshellColours(machine, colourValue),
      CommonSVG.createShellPattern(rand, baseline),
      ILibrary(libraryDeployments[0]).getPart(),
      ILibrary(libraryDeployments[1]).getPart()
    );

    output = string.concat(
      output,
      ILibrary(libraryDeployments[2]).getPart(),
      ILibrary(libraryDeployments[3]).getPart(),
      ILibrary(libraryDeployments[4]).getPart(),
      ILibrary(libraryDeployments[5]).getPart(),
      ILibrary(libraryDeployments[6]).getPart()
    );

    output = string.concat(
      output,
      ILibrary(libraryDeployments[7]).getPart(),
      ILibrary(libraryDeployments[8]).getPart(),
      CommonSVG.TEMP_STYLE,
      CommonSVG.STYLE,
      getAnimationSpeed(baseline)
    );

    return string.concat(
      output,
      ILibrary(libraryDeployments[9]).getPart(),
      ILibrary(libraryDeployments[10]).getPart(),
      ILibrary(libraryDeployments[11]).getPart(),
      ILibrary(libraryDeployments[12]).getPart(),
      CommonSVG.STYLE_CLOSE
    );
  }
}