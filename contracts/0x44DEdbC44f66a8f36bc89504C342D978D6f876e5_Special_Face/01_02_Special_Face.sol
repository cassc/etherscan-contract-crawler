// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Special_Face {
  using Strings for uint256;

  string constant SPECIAL_FACE_FACE_SPECIAL___CLOWN_FACE_PAINT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF////5TMxUGv/////saxS2QAAAAR0Uk5T////AEAqqfQAAABrSURBVHja7NTLCoAwDETRSfz/f5aAaDbRkqJUuNm1MIc2fWibLAEALA/orB4gjQgayt8ICwPSmKAy7znupVDOuychBp8DsWo7qrOFaKLZJah1Cimv3j14zr/6mPiRAAAAAAAAAAD+C+wCDACP0C3R4VTJFQAAAABJRU5ErkJggg==";

  string constant SPECIAL_FACE_FACE_SPECIAL___DRIPPING_HONEY =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF6sU3////Xg8AigAAAAJ0Uk5T/wDltzBKAAAAaUlEQVR42uzTSw6AIAwA0en9L22wJrpRaUlcmGFDAu2j/IjFhoCAgMDnANVxJhe6B7gGQbWCkZRljFyonwEpHF19C3suSTQriDiJoHWN5DSPYZNA+yHxGsbqK/U7CwgICAgICPwQ2AQYAHSlD8A9jYRxAAAAAElFTkSuQmCC";

  function getAsset(uint256 headNum) external pure returns (string memory) {
    if (headNum == 0) {
      return SPECIAL_FACE_FACE_SPECIAL___CLOWN_FACE_PAINT;
    } else if (headNum == 1) {
      return SPECIAL_FACE_FACE_SPECIAL___DRIPPING_HONEY;
    }
    return SPECIAL_FACE_FACE_SPECIAL___CLOWN_FACE_PAINT;
  }
}