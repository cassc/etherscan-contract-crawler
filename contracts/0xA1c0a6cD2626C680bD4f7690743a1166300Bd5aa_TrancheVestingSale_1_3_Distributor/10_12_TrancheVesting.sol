// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Distributor } from "./Distributor.sol";

abstract contract TrancheVesting is Distributor {
  // time and vested fraction must monotonically increase in the tranche array
  struct Tranche {
    uint128 time; // block.timestamp upon which the tranche vests 
    uint128 vestedBips; // fraction of tokens unlockable as basis points (e.g. 100% of vested tokens is 10000)
  }

  Tranche[] public tranches;

  constructor(
    Tranche[] memory _tranches
  ) {
    require(_tranches.length != 0, "tranches required");

    uint128 lastTime = 0;
    uint128 lastVestedBips = 0;
  
    for (uint i = 0; i < _tranches.length;) {
      require(_tranches[i].vestedBips != 0, "tranche vested fraction == 0");
      require(_tranches[i].time > lastTime, "tranche time must increase");
      require(_tranches[i].vestedBips > lastVestedBips, "tranche vested fraction must increase");
      lastTime = _tranches[i].time;
      lastVestedBips = _tranches[i].vestedBips;
      tranches.push(_tranches[i]);
      unchecked {
        ++i;
      }
    }

    require(lastTime <= 4102444800, "vesting ends after 4102444800 (Jan 1 2100)");
    require(lastVestedBips == 10000, "last tranche must vest all tokens");
  }

  function _getVestedBips(address /*beneficiary*/, uint time) public override view returns (uint256) {
    for (uint i = tranches.length; i != 0;) {
      if (time > tranches[i - 1].time) {
        return tranches[i - 1].vestedBips;
      }
      unchecked {
        --i;
      }
    }
    return 0;
  }
}