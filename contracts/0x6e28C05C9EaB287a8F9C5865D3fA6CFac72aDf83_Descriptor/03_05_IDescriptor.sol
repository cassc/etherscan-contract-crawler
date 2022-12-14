// SPDX-License-Identifier: MIT

/// @author notu @notuart

pragma solidity ^0.8.9;

interface IDescriptor {
  struct Traits {
    uint256 accessories;
    uint256 animations;
    uint256 backgrounds;
    uint256 bodies;
    uint256 bottoms;
    uint256 ears;
    uint256 eyes;
    uint256 faces;
    uint256 fx;
    uint256 heads;
    uint256 mouths;
    uint256 overlays;
    uint256 shoes;
    uint256 tops;
  }

  function addTraits(Traits calldata add) external;

  function udpateTraits(Traits calldata updates) external;

  function accessoryExists(uint256 id) external view returns (bool);

  function animationExists(uint256 id) external view returns (bool);

  function backgroundExists(uint256 id) external view returns (bool);

  function bodyExists(uint256 id) external view returns (bool);

  function bottomExists(uint256 id) external view returns (bool);

  function earExists(uint256 id) external view returns (bool);

  function eyeExists(uint256 id) external view returns (bool);

  function faceExists(uint256 id) external view returns (bool);

  function fxExists(uint256 id) external view returns (bool);

  function headExists(uint256 id) external view returns (bool);

  function mouthExists(uint256 id) external view returns (bool);

  function overlayExists(uint256 id) external view returns (bool);

  function shoeExists(uint256 id) external view returns (bool);

  function topExists(uint256 id) external view returns (bool);
}