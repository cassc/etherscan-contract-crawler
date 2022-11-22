// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./LibVoviStorage.sol";

library LibPausable {
  using LibVoviStorage for *;
  
  event Paused(address account);
  event Unpaused(address account);

  function pause() internal {
    LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
    require(!vs.paused, "Pausable: Already paused");
    vs.paused = true;
    emit Paused(msg.sender);
  }

  function unpause() internal {
    LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
    require(vs.paused, "Pausable: Already unpaused");
    vs.paused = false;
    emit Unpaused(msg.sender);
  }

  function enforceNotPaused() internal view {
    LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
    require(!vs.paused, "Pausable: Contract functionality paused");
  }

  function enforcePaused() internal view {
    LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
    require(vs.paused, "Pausable: Contract functionality is not paused");
  }

}