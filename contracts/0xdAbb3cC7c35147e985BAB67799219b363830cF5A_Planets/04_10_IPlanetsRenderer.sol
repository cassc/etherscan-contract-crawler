//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "scripty.sol/contracts/scripty/IScriptyBuilder.sol";
import "./IPlanets.sol";

interface IPlanetsRenderer {
  function buildAnimationURI(bytes calldata vars) external view returns (bytes memory html);
}