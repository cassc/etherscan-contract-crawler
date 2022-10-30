// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.16;

import {DssVestTransferrable} from "./DssVest.sol";

contract Vester is DssVestTransferrable {
    constructor(address _czar, address _gem) DssVestTransferrable(_czar, _gem) {}
}