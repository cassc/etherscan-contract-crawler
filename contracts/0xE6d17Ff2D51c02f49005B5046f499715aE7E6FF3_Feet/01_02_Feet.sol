// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Feet {
  using Strings for uint256;
  string constant FEET_FEET___GOLD_PANDA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABhQTFRF+dZOAAAA7MtK//jb1bY+8vLy8uvQ////Czaq5AAAAAh0Uk5T/////////wDeg71ZAAAAn0lEQVR42uzU0Q6CMAwF0Hvbov//x66AwBQMlcQHc5s9NEt6Nkoz3C8GBAgQIECAAAECBAgQ8FNgsNcdGyoArUVX3oIVALDVsClqgAMjwrzMnFZ68BTYpd8CY14G1lN5HUihBkz1HYBboYl0bPs2c86zQKuPdyD2hV0A4bkWwOCRi4VP2NQvAs/3ABbd5LVxjINRPPgLGR83/ulFeggwAFg0aqXdA+GjAAAAAElFTkSuQmCC";

  string constant FEET_FEET___SMALL_PANDA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF6+vrAAAAyMjI2dnZ////Kx1DFwAAAAV0Uk5T/////wD7tg5TAAAAjUlEQVR42uzU2wqAIAwG4B16/2eupVkjD43AIP5d6WgfTke0vAwCAAAAAAAAAAAAAADAVEBknOkBLOILbM8RgEhOQ1IEAQurssPkZeQODoHdcj6QivgLwB273wMN68uW+CmwFegd0LpQB3T/vgBCKcOBFvTadBY4cAeibvK2cdTGKDZewaKb+NMfaRVgALO8PRmJ8eR8AAAAAElFTkSuQmCC";

  string constant FEET_FEET___SMALL =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFNTU1AAAALS0t////vgF0DAAAAAR0Uk5T////AEAqqfQAAACGSURBVHja7NRZCsAgDATQZLz/nduQVgl1pWChTL6MMA83lPSyhAABAgQIECBAgAABAlsBYDzTAxSIAet1BRBBMeC1CFhZyhZzDVfO4BY0DPcDHtIvgLDs/h5kmM+t6CxwBvQJaF2oA05kAB6fBlLMF2HhDKDh5VnXeIqNW7DqTvzpRzoEGADxri3xIUc9nwAAAABJRU5ErkJggg==";

  function getAsset(uint256 assetNum) external pure returns (string memory) {
    if (assetNum == 0) {
      return FEET_FEET___GOLD_PANDA;
    } else if (assetNum == 1) {
      return FEET_FEET___SMALL_PANDA; // polar / reverse_panda
    } else if (assetNum == 2) {
      return FEET_FEET___SMALL; // black / panda
    }
    return FEET_FEET___SMALL;
  }
}