// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;

import { FactoryLib } from "./factory/FactoryLib.sol";
import { ZeroUnderwriterLock } from "../underwriter/ZeroUnderwriterLock.sol";

/**
@title lockFor implementation
@author raymondpulver
*/
library LockForImplLib {
  function lockFor(
    address nft,
    address underwriterLockImpl,
    address underwriter
  ) internal view returns (ZeroUnderwriterLock result) {
    result = ZeroUnderwriterLock(
      FactoryLib.computeAddress(nft, underwriterLockImpl, bytes32(uint256(uint160(underwriter))))
    );
  }
}