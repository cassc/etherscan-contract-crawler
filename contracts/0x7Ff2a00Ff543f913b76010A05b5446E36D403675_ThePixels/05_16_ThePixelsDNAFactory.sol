// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract ThePixelsDNAFactory {
  uint8 constant internal maxRarityScore = 101;

  uint8 constant internal themePastelRarity = 0;
  uint8 constant internal themeZombieRarity = 80;
  uint8 constant internal themeAlienRarity = 95;

  uint8 constant internal baseDNARarity = 99;
  uint8 constant internal costumeDNARarity = 10;

  mapping (uint8 => uint8[]) public traitTable;
  // Base DNA parts:
  uint8[3] internal themes;
  uint8[18] internal bodies;
  uint8[5] internal faces;
  uint8[8] internal eyes;
  uint8[11] internal noses;
  uint8[9] internal mouths;
  // Dynamic DNA parts:
  uint8[5] internal costumes;           //6 - 1
  uint8[46] internal headAccessories;   //7 - 2
  uint8[18] internal hairs;             //8 - 3
  uint8[25] internal sunglasses;        //9 - 4
  uint8[7] internal facialHairs;        //10 - 5

  function _getRandomDNA(uint256 _seed, uint256 _nonce) internal view returns (uint8[11] memory) {
    uint256 r = _rnd(_seed, _nonce) % maxRarityScore;

    if (r > themeAlienRarity) {
      return _getAlienDNA(_seed, _nonce + 1);
    }else if (r > themeZombieRarity) {
      return _getZombieDNA(_seed, _nonce + 2);
    }else {
      return _getPastelDNA(_seed, _nonce + 3);
    }
  }

  function _getPastelDNA(uint256 _seed, uint256 _nonce) internal view returns (uint8[11] memory) {
    uint256 r = _rnd(_seed, _nonce) % maxRarityScore;
    uint8[11] memory finalDNA = _getBaseDNA(_seed, _nonce + 1, 0);
    uint256 nextNonce = _nonce + 13;

    //99 - 100
    if (r >= baseDNARarity) {
      return finalDNA;

    // 54 - 99
    }else if (r < baseDNARarity && r >= 54) {
      finalDNA[7] = _pickTrait(7, _seed, nextNonce + 2);
      finalDNA[9] = _pickTrait(9, _seed, nextNonce + 3);
      finalDNA[10] = _pickTrait(10, _seed, nextNonce + 4);

    // 54 - 32
    }else if (r < 54 && r >= 32) {
      finalDNA[7] = _pickTrait(7, _seed, nextNonce + 2);
      finalDNA[9] = _pickTrait(9, _seed, nextNonce + 3);

    // 32 - 10
    }else if (r < 32 && r >= costumeDNARarity) {
      finalDNA[8] = _pickTrait(8, _seed, nextNonce + 5);
      finalDNA[9] = _pickTrait(9, _seed, nextNonce + 6);

    // 0 - 10
    }else {
      finalDNA[6] = _pickTrait(6, _seed, nextNonce + 7);
      finalDNA[9] = _pickTrait(9, _seed, nextNonce + 8);
      finalDNA[10] = _pickTrait(10, _seed, nextNonce + 9);
    }
    return finalDNA;
  }

  function _getZombieDNA(uint256 _seed, uint256 _nonce) internal view returns (uint8[11] memory) {
    uint256 r = _rnd(_seed, _nonce) % maxRarityScore;
    uint8[11] memory finalDNA = _getBaseDNA(_seed, _nonce + 1, 1);
    uint256 nextNonce = _nonce + 13;

    if (r >= baseDNARarity) {
      return finalDNA;

    // 54 - 99
    }else if (r < baseDNARarity && r >= 54) {
      finalDNA[7] = _pickTrait(7, _seed, nextNonce + 2);
      finalDNA[9] = _pickTrait(9, _seed, nextNonce + 3);
      finalDNA[10] = _pickTrait(10, _seed, nextNonce + 4);

    // 54 - 32
    }else if (r < 54 && r >= 32) {
      finalDNA[7] = _pickTrait(7, _seed, nextNonce + 2);
      finalDNA[9] = _pickTrait(9, _seed, nextNonce + 3);

    // 32 - 10
    }else if (r < 32 && r >= costumeDNARarity) {
      finalDNA[8] = _pickTrait(8, _seed, nextNonce + 5);
      finalDNA[9] = _pickTrait(9, _seed, nextNonce + 6);

    // 0 - 10
    }else {
      finalDNA[6] = _pickTrait(6, _seed, nextNonce + 7);
      finalDNA[9] = _pickTrait(9, _seed, nextNonce + 8);
      finalDNA[10] = _pickTrait(10, _seed, nextNonce + 9);
    }
    return finalDNA;
  }

  function _getAlienDNA(uint256 _seed, uint256 _nonce) internal view returns (uint8[11] memory) {
    uint256 r = _rnd(_seed, _nonce) % maxRarityScore;
    uint8[11] memory finalDNA = _getBaseDNA(_seed, _nonce + 1, 2);
    uint256 nextNonce = _nonce + 13;

    if (r >= baseDNARarity) {
      return finalDNA;

    }else if (r < baseDNARarity && r >= 50) {
      finalDNA[7] = _pickTrait(7, _seed, nextNonce + 2);

    }else if (r < 50 && r >= costumeDNARarity) {
      finalDNA[8] = _pickTrait(8, _seed, nextNonce + 3);

    }else {
      finalDNA[6] = _pickTrait(6, _seed, nextNonce + 4);
    }
    return finalDNA;
  }

  function _getBaseDNA(uint256 _seed, uint256 _nonce, uint8 _theme) internal view returns (uint8[11] memory) {
    uint8[11] memory dna;
    dna[0] = _theme;
    if (_theme == 2) {
      dna[1] = _pickTrait(1, _seed, _nonce + 1);
      dna[2] = _pickTrait(2, _seed, _nonce + 2);
      dna[3] = 8;
      dna[4] = _pickTrait(4, _seed, _nonce + 4);
      dna[5] = _pickTrait(5, _seed, _nonce + 5);
    }else{
      dna[1] = _pickTrait(1, _seed, _nonce + 6);
      dna[2] = _pickTrait(2, _seed, _nonce + 7);
      dna[3] = _pickTrait(3, _seed, _nonce + 8);
      dna[4] = _pickTrait(4, _seed, _nonce + 9);
      dna[5] = _pickTrait(5, _seed, _nonce + 10);
    }
    return dna;
  }

  function _pickTrait(uint8 traitIndex, uint256 _seed, uint256 _nonce) internal view returns (uint8) {
    uint256 beginIndex = _rnd(_seed, _seed + _nonce + traitIndex);
    uint256 r = beginIndex % maxRarityScore;

    uint8[] memory _traits = traitTable[traitIndex];
    for (uint256 i=beginIndex; i<beginIndex + _traits.length; i++) {
      uint256 index = i % _traits.length;
      if (_traits[index] <= r) {
        return uint8(index);
      }
    }
    return uint8(beginIndex);
  }

  function _setBodyRarities() internal {
    bodies[0] = 0;
    bodies[1] = 0;
    bodies[2] = 10;
    bodies[3] = 95;
    bodies[4] = 15;
    bodies[5] = 0;
    bodies[6] = 5;
    bodies[7] = 0;
    bodies[8] = 0;
    bodies[9] = 35;
    bodies[10] = 0;
    bodies[11] = 15;
    bodies[12] = 25;
    bodies[13] = 25;
    bodies[14] = 20;
    bodies[15] = 30;
    bodies[16] = 20;
    bodies[17] = 30;
  }

  function _setFaceRarities() internal {
    faces[0] = 0;
    faces[1] = 0;
    faces[2] = 0;
    faces[3] = 5;
    faces[4] = 10;
  }

  function _setEyesRarities() internal {
    eyes[0] = 0;
    eyes[1] = 0;
    eyes[2] = 10;
    eyes[3] = 15;
    eyes[4] = 5;
    eyes[5] = 5;
    eyes[6] = 30;
    eyes[7] = 30;
  }

  function _setNoseRarities() internal {
    noses[0] = 15;
    noses[1] = 15;
    noses[2] = 5;
    noses[3] = 25;
    noses[4] = 0;
    noses[5] = 0;
    noses[6] = 50;
    noses[7] = 0;
    noses[8] = 0;
    noses[9] = 20;
    noses[10] = 20;
  }

  function _setMouthRarities() internal {
    mouths[0] = 0;
    mouths[1] = 10;
    mouths[2] = 15;
    mouths[3] = 20;
    mouths[4] = 80;
    mouths[5] = 40;
    mouths[6] = 30;
    mouths[7] = 65;
    mouths[8] = 25;
  }

  function _setCostumeRarities() internal {
    costumes[0] = 0;
    costumes[1] = 75;
    costumes[2] = 85;
    costumes[3] = 55;
    costumes[4] = 75;
  }

  function _setHeadAccessoryRarities() internal {
    headAccessories[0] = 0;
    headAccessories[1] = 35;
    headAccessories[2] = 50;

    headAccessories[3] = 20;
    headAccessories[4] = 20;
    headAccessories[5] = 20;
    headAccessories[6] = 20;

    headAccessories[7] = 0;
    headAccessories[8] = 0;
    headAccessories[9] = 0;

    headAccessories[10] = 90;
    headAccessories[11] = 90;
    headAccessories[12] = 90;

    headAccessories[13] = 0;
    headAccessories[14] = 0;
    headAccessories[15] = 0;
    headAccessories[16] = 0;
    headAccessories[17] = 0;

    headAccessories[18] = 35;
    headAccessories[19] = 35;
    headAccessories[20] = 35;
    headAccessories[21] = 35;

    headAccessories[22] = 0;

    headAccessories[23] = 80;

    headAccessories[24] = 0;
    headAccessories[25] = 0;
    headAccessories[26] = 0;

    headAccessories[27] = 70;

    headAccessories[28] = 30;
    headAccessories[29] = 30;
    headAccessories[30] = 30;
    headAccessories[31] = 30;

    headAccessories[32] = 5;
    headAccessories[33] = 5;
    headAccessories[34] = 5;

    headAccessories[35] = 30;
    headAccessories[36] = 30;
    headAccessories[37] = 30;

    headAccessories[38] = 95;

    headAccessories[39] = 40;

    headAccessories[40] = 98;

    headAccessories[41] = 75;

    headAccessories[42] = 15;
    headAccessories[43] = 15;
    headAccessories[44] = 15;
    headAccessories[45] = 15;
  }

  function _setHairRarities() internal {
    hairs[0] = 55;
    hairs[1] = 40;
    hairs[2] = 40;
    hairs[3] = 0;
    hairs[4] = 35;
    hairs[5] = 5;
    hairs[6] = 0;
    hairs[7] = 15;
    hairs[8] = 80;
    hairs[9] = 20;
    hairs[10] = 25;
    hairs[11] = 30;
    hairs[12] = 50;
    hairs[13] = 50;
    hairs[14] = 90;
    hairs[15] = 50;
    hairs[16] = 50;
    hairs[17] = 20;
  }

  function _setSunglassesRarities() internal {
    sunglasses[0] = 0;
    sunglasses[1] = 40;
    sunglasses[2] = 55;
    sunglasses[3] = 80;
    sunglasses[4] = 25;
    sunglasses[5] = 85;
    sunglasses[6] = 25;
    sunglasses[7] = 20;
    sunglasses[8] = 35;
    sunglasses[9] = 10;
    sunglasses[10] = 95;
    sunglasses[11] = 30;
    sunglasses[12] = 70;
    sunglasses[13] = 90;

    sunglasses[14] = 70;
    sunglasses[15] = 80;
    sunglasses[16] = 60;
    sunglasses[17] = 90;
    sunglasses[18] = 60;
    sunglasses[19] = 55;
    sunglasses[20] = 70;
    sunglasses[21] = 55;
    sunglasses[22] = 60;
    sunglasses[23] = 65;
    sunglasses[24] = 85;
  }

  function _setFacialHairRarities() internal {
    facialHairs[0] = 50;
    facialHairs[1] = 0;
    facialHairs[2] = 10;
    facialHairs[3] = 20;
    facialHairs[4] = 50;
    facialHairs[5] = 60;
    facialHairs[6] = 70;
  }

  function _setTraitTable() internal {
    _setBodyRarities();
    _setFaceRarities();
    _setEyesRarities();
    _setNoseRarities();
    _setMouthRarities();

    _setCostumeRarities();
    _setHeadAccessoryRarities();
    _setHairRarities();
    _setSunglassesRarities();
    _setFaceRarities();

    traitTable[0] = themes;
    traitTable[1] = bodies;
    traitTable[2] = faces;
    traitTable[3] = eyes;
    traitTable[4] = noses;
    traitTable[5] = mouths;
    traitTable[6] = costumes;
    traitTable[7] = headAccessories;
    traitTable[8] = hairs;
    traitTable[9] = sunglasses;
    traitTable[10] = facialHairs;
  }

  function _rnd(uint256 _salt, uint256 _nonce) internal view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _salt, _nonce)));
  }
}