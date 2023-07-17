// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;
import "hardhat/console.sol";

contract BattleStats {
  uint8 NO_STAT = 5;
  uint8[4] public tierToStatBase;
  uint8[3][6] public rarityToTiers;

  constructor() {
    tierToStatBase[0] = 0;
    tierToStatBase[1] = 0;
    tierToStatBase[2] = 3;
    tierToStatBase[3] = 6;

    rarityToTiers[0] = [1, 0, 0];
    rarityToTiers[1] = [2, 0, 0];
    rarityToTiers[2] = [2, 1, 0];
    rarityToTiers[3] = [2, 2, 0];
    rarityToTiers[4] = [3, 2, 1];
    rarityToTiers[5] = [3, 2, 2];
  }

  function getMajorType(uint256 mgear) public pure returns (uint8) {
    return uint8((mgear >> 19) & 0x3);
  }

  function getMinorType1(uint256 mgear) public view returns (uint8) {
    if (rarityToTiers[uint8(mgear & 0x7)][1] == 0) {
      return NO_STAT;
    }
    return uint8((mgear >> 21) & 0x3);
  }

  function getMinorType2(uint256 mgear) public view returns (uint8) {
    if (rarityToTiers[uint8(mgear & 0x7)][2] == 0) {
      return NO_STAT;
    }
    return uint8((mgear >> 23) & 0x3);
  }

  function getMajorValue(uint256 mgear) public view returns (uint8) {
    return tierToStatBase[rarityToTiers[uint8(mgear & 0x7)][0]] + uint8((mgear >> 25) & 0x3);
  }

  function getMinorValue1(uint256 mgear) public view returns (uint8) {
    if (rarityToTiers[uint8(mgear & 0x7)][1] == 0) {
      return 0;
    }
    return tierToStatBase[rarityToTiers[uint8(mgear & 0x7)][1]] + uint8((mgear >> 27) & 0x3);
  }

  function getMinorValue2(uint256 mgear) public view returns (uint8) {
    if (rarityToTiers[uint8(mgear & 0x7)][2] == 0) {
      return 0;
    }
    return tierToStatBase[rarityToTiers[uint8(mgear & 0x7)][2]] + uint8((mgear >> 29) & 0x3);
  }
}