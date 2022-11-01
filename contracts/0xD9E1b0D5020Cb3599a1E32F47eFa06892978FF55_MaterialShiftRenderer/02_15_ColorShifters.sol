// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import '@openzeppelin/contracts/utils/Strings.sol';
import '../libraries/ColorUtils.sol';

library ColorShifters {
  uint8 public constant NUM_MATERIALS = 8;

  //amt : 20
  function colorFlip(bytes memory colors, uint8 amt)
    public
    pure
    returns (bytes memory)
  {
    bytes memory colorsTemp = abi.encodePacked(colors);
    for (uint256 i = 0; i < NUM_MATERIALS; i++) {
      bytes memory rgbNew = ColorUtils.getColor(
        colorsTemp,
        NUM_MATERIALS - i - 1
      );
      bytes memory rgbOld = ColorUtils.getColor(colorsTemp, i);
      if (rgbNew[0] > rgbOld[0]) {
        rgbOld = ColorUtils.add(
          rgbOld,
          0,
          (uint16(uint8(rgbNew[0]) - uint8(rgbOld[0])) * uint16(amt)) / 40
        );
      } else {
        rgbOld = ColorUtils.sub(
          rgbOld,
          0,
          (uint16(uint8(rgbOld[0]) - uint8(rgbNew[0])) * uint16(amt)) / 40
        );
      }
      if (rgbNew[1] > rgbOld[1]) {
        rgbOld = ColorUtils.add(
          rgbOld,
          1,
          (uint16(uint8(rgbNew[1]) - uint8(rgbOld[1])) * uint16(amt)) / 40
        );
      } else {
        rgbOld = ColorUtils.sub(
          rgbOld,
          1,
          (uint16(uint8(rgbOld[1]) - uint8(rgbNew[1])) * uint16(amt)) / 40
        );
      }
      if (rgbNew[2] > rgbOld[2]) {
        rgbOld = ColorUtils.add(
          rgbOld,
          2,
          (uint16(uint8(rgbNew[2]) - uint8(rgbOld[2])) * uint16(amt)) / 40
        );
      } else {
        rgbOld = ColorUtils.sub(
          rgbOld,
          2,
          (uint16(uint8(rgbOld[2]) - uint8(rgbNew[2])) * uint16(amt)) / 40
        );
      }
      colors = ColorUtils.setColor(colors, i, rgbOld);
    }
    return colors;
  }

  function testHSV(bytes memory colors) public pure returns (bytes memory) {
    for (uint256 i = 0; i < NUM_MATERIALS; i++) {
      colors = ColorUtils.setColor(
        colors,
        i,
        ColorUtils.HSVtoRGB(ColorUtils.RGBtoHSV(ColorUtils.getColor(colors, i)))
      );
    }
    return colors;
  }

  //amt : 60
  function hueHighlight(bytes memory colors, uint8 amt)
    public
    pure
    returns (bytes memory)
  {
    for (uint8 i = 0; i < NUM_MATERIALS; i++) {
      bytes memory hsv = ColorUtils.RGBtoHSV(ColorUtils.getColor(colors, i));
      if (i == NUM_MATERIALS - 1) {
        hsv = ColorUtils.subWrap(hsv, 0, amt / 3);
        hsv = ColorUtils.add(hsv, 2, amt / 2);
      } else if (i < NUM_MATERIALS / 2) {
        uint16 shift = uint16(NUM_MATERIALS / 2 - i) * uint16(amt);
        hsv = ColorUtils.add(hsv, 1, shift);
      } else {
        uint16 shift = uint16(i - NUM_MATERIALS / 2) * uint16(amt);
        hsv = ColorUtils.sub(hsv, 1, shift);
      }
      colors = ColorUtils.setColor(colors, i, ColorUtils.HSVtoRGB(hsv));
    }
    return colors;
  }

  //amt : 50
  function twoToneHue(bytes memory colors, uint8 amt)
    public
    pure
    returns (bytes memory)
  {
    for (uint8 i = 0; i < NUM_MATERIALS; i++) {
      bytes memory hsv = ColorUtils.RGBtoHSV(ColorUtils.getColor(colors, i));
      if (i <= (NUM_MATERIALS / 3) * 2) {
        hsv = ColorUtils.subWrap(hsv, 0, amt);
        //hsv = ColorUtils.sub(hsv, 2, amt/2);
      } else {
        hsv = ColorUtils.addWrap(hsv, 0, amt);
        //hsv = ColorUtils.add(hsv, 2, amt);
      }
      colors = ColorUtils.setColor(colors, i, ColorUtils.HSVtoRGB(hsv));
    }
    return colors;
  }

  function corrupted(bytes memory colors, uint8 amt)
    public
    pure
    returns (bytes memory)
  {
    for (uint8 i = 0; i < NUM_MATERIALS; i++) {
      bytes memory hsv = ColorUtils.RGBtoHSV(ColorUtils.getColor(colors, i));
      hsv = ColorUtils.sub(hsv, 2, uint16(amt));
      colors = ColorUtils.setColor(colors, i, ColorUtils.HSVtoRGB(hsv));
    }
    return colors;
  }

  function glow(bytes memory colors, uint8 amt)
    public
    pure
    returns (bytes memory)
  {
    for (uint8 i = 0; i < NUM_MATERIALS; i++) {
      bytes memory hsv = ColorUtils.RGBtoHSV(ColorUtils.getColor(colors, i));
      hsv = ColorUtils.add(hsv, 2, uint16(amt) * i);
      if (i < NUM_MATERIALS / 2) {
        uint16 shift = uint16(NUM_MATERIALS / 2 - i) * uint16(amt);
        hsv = ColorUtils.add(hsv, 1, shift);
      } else {
        uint16 shift = uint16(i - NUM_MATERIALS / 2) * uint16(amt);
        hsv = ColorUtils.sub(hsv, 1, shift);
      }
      colors = ColorUtils.setColor(colors, i, ColorUtils.HSVtoRGB(hsv));
    }
    return colors;
  }

  function blackGlow(bytes memory colors, uint8 amt)
    public
    pure
    returns (bytes memory)
  {
    for (uint8 i = 0; i < NUM_MATERIALS; i++) {
      bytes memory hsv = ColorUtils.RGBtoHSV(ColorUtils.getColor(colors, i));
      hsv = ColorUtils.sub(hsv, 2, uint16((amt / 3) * 2) * i);
      if (i < NUM_MATERIALS / 2) {
        uint16 shift = uint16(NUM_MATERIALS / 2 - i) * uint16(amt);
        hsv = ColorUtils.add(hsv, 1, shift / 2);
        hsv = ColorUtils.add(hsv, 2, shift);
      } else {
        uint16 shift = uint16(i - NUM_MATERIALS / 2) * uint16(amt);
        hsv = ColorUtils.add(hsv, 1, shift / 2);
      }
      colors = ColorUtils.setColor(colors, i, ColorUtils.HSVtoRGB(hsv));
    }
    return colors;
  }

  function hueShift(bytes memory colors, uint8 amt)
    public
    pure
    returns (bytes memory)
  {
    for (uint8 i = 0; i < NUM_MATERIALS; i++) {
      bytes memory hsv = ColorUtils.RGBtoHSV(ColorUtils.getColor(colors, i));
      hsv = ColorUtils.addWrap(hsv, 0, amt);
      colors = ColorUtils.setColor(colors, i, ColorUtils.HSVtoRGB(hsv));
    }
    return colors;
  }

  function saturationShift(bytes memory colors, uint8 amt)
    public
    pure
    returns (bytes memory)
  {
    for (uint8 i = 0; i < NUM_MATERIALS; i++) {
      bytes memory hsv = ColorUtils.RGBtoHSV(ColorUtils.getColor(colors, i));
      hsv = ColorUtils.add(hsv, 1, amt);
      colors = ColorUtils.setColor(colors, i, ColorUtils.HSVtoRGB(hsv));
    }
    return colors;
  }

  function valueShift(bytes memory colors, uint8 amt)
    public
    pure
    returns (bytes memory)
  {
    for (uint8 i = 0; i < NUM_MATERIALS; i++) {
      bytes memory hsv = ColorUtils.RGBtoHSV(ColorUtils.getColor(colors, i));
      hsv = ColorUtils.add(hsv, 2, amt);
      colors = ColorUtils.setColor(colors, i, ColorUtils.HSVtoRGB(hsv));
    }
    return colors;
  }

  function contrast(bytes memory colors, uint8 amt)
    public
    pure
    returns (bytes memory)
  {
    for (uint8 i = 0; i < NUM_MATERIALS; i++) {
      bytes memory hsv = ColorUtils.RGBtoHSV(ColorUtils.getColor(colors, i));
      if (i < NUM_MATERIALS / 2) {
        uint16 shift = uint16(NUM_MATERIALS / 2 - i) * uint16(amt);
        hsv = ColorUtils.sub(hsv, 2, shift);
      } else {
        uint16 shift = uint16(i - NUM_MATERIALS / 2) * uint16(amt);
        hsv = ColorUtils.add(hsv, 2, shift);
      }
      colors = ColorUtils.setColor(colors, i, ColorUtils.HSVtoRGB(hsv));
    }
    return colors;
  }

  //amt : 40
  function colorContrast(bytes memory colors, uint8 amt)
    public
    pure
    returns (bytes memory)
  {
    for (uint8 i = 0; i < NUM_MATERIALS; i++) {
      bytes memory hsv = ColorUtils.RGBtoHSV(ColorUtils.getColor(colors, i));
      if (i < NUM_MATERIALS / 2) {
        uint16 shift = uint16(NUM_MATERIALS / 2 - i) * uint16(amt);
        hsv = ColorUtils.add(hsv, 1, shift);
      } else {
        uint16 shift = uint16(i - NUM_MATERIALS / 2) * uint16(amt);
        hsv = ColorUtils.sub(hsv, 1, shift);
      }
      colors = ColorUtils.setColor(colors, i, ColorUtils.HSVtoRGB(hsv));
    }
    return colors;
  }

  //amt : 60
  function hueContrast(bytes memory colors, uint8 amt)
    public
    pure
    returns (bytes memory)
  {
    for (uint8 i = 0; i < NUM_MATERIALS; i++) {
      bytes memory hsv = ColorUtils.RGBtoHSV(ColorUtils.getColor(colors, i));
      if (i < NUM_MATERIALS / 2) {
        uint16 shift = uint16(NUM_MATERIALS / 2 - i) * uint16(amt);
        hsv = ColorUtils.addWrap(hsv, 0, shift);
      } else {
        uint16 shift = uint16(i - NUM_MATERIALS / 2) * uint16(amt);
        hsv = ColorUtils.subWrap(hsv, 0, shift);
      }
      colors = ColorUtils.setColor(colors, i, ColorUtils.HSVtoRGB(hsv));
    }
    return colors;
  }
}