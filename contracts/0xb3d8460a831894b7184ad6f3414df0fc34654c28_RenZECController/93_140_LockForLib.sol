// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;

import { ZeroUnderwriterLock } from "../underwriter/ZeroUnderwriterLock.sol";
import { LockForImplLib } from "./LockForImplLib.sol";

/**
@title lockFor for external linking
@author raymondpulver
*/
library LockForLib {
  function lockFor(
    address nft,
    address underwriterLockImpl,
    address underwriter
  ) external view returns (ZeroUnderwriterLock result) {
    result = LockForImplLib.lockFor(nft, underwriterLockImpl, underwriter);
  }
}