//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.15;

import "./DSGuard.sol";
import "./DSAuth.sol";

import { FlashloanData } from "../../core/types/Common.sol";
import { IAccountImplementation } from "../../interfaces/dpm/IAccountImplementation.sol";
import { IAccountGuard } from "../../interfaces/dpm/IAccountGuard.sol";

contract ProxyPermission {
  address internal constant FACTORY_ADDRESS = 0x5a15566417e6C1c9546523066500bDDBc53F88C7;

  bytes4 public constant ALLOWED_METHOD_HASH = bytes4(keccak256("execute(address,bytes)"));

  function givePermission(bool isDPMProxy, address _contractAddr) public {
    if (isDPMProxy) {
      // DPM permission
      IAccountGuard(IAccountImplementation(address(this)).guard()).permit(
        _contractAddr,
        address(this),
        true
      );
    } else {
      // DSProxy permission
      address currAuthority = address(DSAuth(address(this)).authority());
      DSGuard guard = DSGuard(currAuthority);
      if (currAuthority == address(0)) {
        guard = DSGuardFactory(FACTORY_ADDRESS).newGuard();
        DSAuth(address(this)).setAuthority(DSAuthority(address(guard)));
      }

      if (!guard.canCall(_contractAddr, address(this), ALLOWED_METHOD_HASH)) {
        guard.permit(_contractAddr, address(this), ALLOWED_METHOD_HASH);
      }
    }
  }

  function removePermission(bool isDPMProxy, address _contractAddr) public {
    if (isDPMProxy) {
      // DPM permission
      IAccountGuard(IAccountImplementation(address(this)).guard()).permit(
        _contractAddr,
        address(this),
        false
      );
    } else {
      // DSProxy permission
      address currAuthority = address(DSAuth(address(this)).authority());
      if (currAuthority == address(0)) {
        return;
      }
      DSGuard guard = DSGuard(currAuthority);
      guard.forbid(_contractAddr, address(this), ALLOWED_METHOD_HASH);
    }
  }
}