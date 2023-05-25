// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {StableDebtToken} from '../../protocol/tokenization/StableDebtToken.sol';
import {IL1Pool} from '../../interfaces/IL1Pool.sol';

contract MockStableDebtToken is StableDebtToken {
  constructor(IL1Pool pool) StableDebtToken(pool) {}

  function getRevision() internal pure override returns (uint256) {
    return 0x3;
  }
}