// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IMooEgg {
  enum EggCategory {
    NONE,
    WHITE,
    RAINBOW,
    GOLDEN,
    DIAMOND,
    WHITE_GEN_2,
    RAINBOW_GEN_2,
    GOLDEN_GEN_2,
    DIAMOND_GEN_2
  }

  function currentTokenId() external view returns (uint256);

  function mint(address _to, EggCategory category) external;
}