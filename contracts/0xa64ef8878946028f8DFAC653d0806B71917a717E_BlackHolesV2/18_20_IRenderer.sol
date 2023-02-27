// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./BlackHole.sol";

interface IRenderer {
  function PIXELS_PER_SIDE() external view returns (uint256);

  function getBlackHoleSVG(BlackHole memory _blackHole) external view returns (string memory);
}