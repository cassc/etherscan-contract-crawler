// SPDX-License-Identifier: MIT

/// @author notu @notuart

pragma solidity ^0.8.9;

import './interfaces/IDescriptor.sol';
import './Authorizable.sol';

contract Descriptor is IDescriptor, Authorizable {
  Traits public traits;

  constructor() Authorizable() {
    traits = Traits({
      accessories: 17,
      animations: 0,
      backgrounds: 26,
      bodies: 71,
      bottoms: 0,
      ears: 8,
      eyes: 84,
      faces: 53,
      fx: 0,
      heads: 368,
      mouths: 60,
      overlays: 6,
      shoes: 0,
      tops: 95
    });
  }

  // Convenient way to add new traits
  function addTraits(Traits calldata add) external onlyAuthorized {
    traits = Traits({
      accessories: traits.accessories + add.accessories,
      animations: traits.animations + add.animations,
      backgrounds: traits.backgrounds + add.backgrounds,
      bodies: traits.bodies + add.bodies,
      bottoms: traits.bottoms + add.bottoms,
      ears: traits.ears + add.ears,
      eyes: traits.eyes + add.eyes,
      faces: traits.faces + add.faces,
      fx: traits.fx + add.fx,
      heads: traits.heads + add.heads,
      mouths: traits.mouths + add.mouths,
      overlays: traits.overlays + add.overlays,
      shoes: traits.shoes + add.shoes,
      tops: traits.tops + add.tops
    });
  }

  // Override all traits at once
  function udpateTraits(Traits calldata updates) external onlyAuthorized {
    traits = updates;
  }

  function accessoryExists(uint256 id) external view returns (bool) {
    return id < traits.accessories;
  }

  function animationExists(uint256 id) external view returns (bool) {
    return id < traits.animations;
  }

  function backgroundExists(uint256 id) external view returns (bool) {
    return id < traits.backgrounds;
  }

  function bodyExists(uint256 id) external view returns (bool) {
    return id < traits.bodies;
  }

  function bottomExists(uint256 id) external view returns (bool) {
    return id < traits.bottoms;
  }

  function earExists(uint256 id) external view returns (bool) {
    return id < traits.ears;
  }

  function eyeExists(uint256 id) external view returns (bool) {
    return id < traits.eyes;
  }

  function faceExists(uint256 id) external view returns (bool) {
    return id < traits.faces;
  }

  function fxExists(uint256 id) external view returns (bool) {
    return id < traits.fx;
  }

  function headExists(uint256 id) external view returns (bool) {
    return id < traits.heads;
  }

  function mouthExists(uint256 id) external view returns (bool) {
    return id < traits.mouths;
  }

  function overlayExists(uint256 id) external view returns (bool) {
    return id < traits.overlays;
  }

  function shoeExists(uint256 id) external view returns (bool) {
    return id < traits.shoes;
  }

  function topExists(uint256 id) external view returns (bool) {
    return id < traits.tops;
  }
}