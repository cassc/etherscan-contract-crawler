// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {SipherNFT} from './SipherNFT.sol';

contract SipherINU is SipherNFT {
  constructor() SipherNFT("Sipher INU", "INU") {}
}