// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {DssVestTransferrable} from "dss-vest/DssVest.sol";

contract Vester is DssVestTransferrable {
  constructor(address _czar, address _gem) DssVestTransferrable(_czar, _gem) {}
}