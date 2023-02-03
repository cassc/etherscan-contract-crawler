// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// solhint-disable-next-line max-line-length
import {PausableUpgradeable as OZPausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import {Base} from "./Base.sol";
import "./Routing.sol" as Routing;

abstract contract PausableUpgradeable is Base, OZPausableUpgradeable {
  function pause() external onlyOperators([Routing.Keys.PauserAdmin, Routing.Keys.ProtocolAdmin]) {
    _pause();
  }

  function unpause()
    external
    onlyOperators([Routing.Keys.PauserAdmin, Routing.Keys.ProtocolAdmin])
  {
    _unpause();
  }
}