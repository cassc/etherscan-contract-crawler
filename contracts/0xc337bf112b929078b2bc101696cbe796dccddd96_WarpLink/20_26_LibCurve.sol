// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ICurvePoolKind1, ICurvePoolKind2, ICurvePoolKind3} from '../interfaces/external/ICurvePool.sol';

library LibCurve {
  error UnhandledPoolKind();

  function exchange(
    uint8 kind,
    bool underlying,
    address pool,
    uint256 eth,
    uint8 i,
    uint8 j,
    uint256 dx,
    uint256 min_dy
  ) internal {
    if (kind == 1) {
      if (underlying) {
        ICurvePoolKind1(pool).exchange_underlying{value: eth}(
          int128(uint128(i)),
          int128(uint128(j)),
          dx,
          min_dy
        );
      } else {
        ICurvePoolKind1(pool).exchange{value: eth}(
          int128(uint128(i)),
          int128(uint128(j)),
          dx,
          min_dy
        );
      }
    } else if (kind == 2) {
      if (underlying) {
        ICurvePoolKind2(pool).exchange_underlying{value: eth}(
          int128(uint128(i)),
          int128(uint128(j)),
          dx,
          min_dy
        );
      } else {
        ICurvePoolKind2(pool).exchange{value: eth}(
          int128(uint128(i)),
          int128(uint128(j)),
          dx,
          min_dy
        );
      }
    } else if (kind == 3) {
      if (underlying) {
        ICurvePoolKind3(pool).exchange_underlying{value: eth}(uint256(i), uint256(j), dx, min_dy);
      } else {
        ICurvePoolKind3(pool).exchange{value: eth}(uint256(i), uint256(j), dx, min_dy);
      }
    } else {
      revert UnhandledPoolKind();
    }
  }
}