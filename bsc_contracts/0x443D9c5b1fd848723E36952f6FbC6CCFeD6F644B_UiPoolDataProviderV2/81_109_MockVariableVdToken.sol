// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {VariableVdToken} from '../../protocol/tokenization/VariableVdToken.sol';

contract MockVariableVdToken is VariableVdToken {
  function getRevision() internal pure override returns (uint256) {
    return 0x2;
  }
}