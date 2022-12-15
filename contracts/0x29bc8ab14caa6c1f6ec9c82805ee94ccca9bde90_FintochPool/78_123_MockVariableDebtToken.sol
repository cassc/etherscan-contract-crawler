// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {VariableDebtToken} from '../../protocol/tokenization/VariableDebtToken.sol';
import {IL1Pool} from '../../interfaces/IL1Pool.sol';

contract MockVariableDebtToken is VariableDebtToken {
  constructor(IL1Pool pool) VariableDebtToken(pool) {}

  function getRevision() internal pure override returns (uint256) {
    return 0x3;
  }
}