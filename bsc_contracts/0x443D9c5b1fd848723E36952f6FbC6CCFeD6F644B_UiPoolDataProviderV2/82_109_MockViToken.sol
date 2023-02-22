// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {ViToken} from '../../protocol/tokenization/ViToken.sol';
import {ILendingPool} from '../../interfaces/ILendingPool.sol';
import {IViniumIncentivesController} from '../../interfaces/IViniumIncentivesController.sol';

contract MockViToken is ViToken {
  function getRevision() internal pure override returns (uint256) {
    return 0x2;
  }
}