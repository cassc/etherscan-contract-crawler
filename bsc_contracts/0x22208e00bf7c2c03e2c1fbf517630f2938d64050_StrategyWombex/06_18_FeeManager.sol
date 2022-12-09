// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./StratManager.sol";

abstract contract FeeManager is StratManager {
    uint constant public VAULT_FEE = 100;
    uint constant public CALL_FEE = 100;
    uint constant public PROTOCOL_FEE = 300;
    uint constant public HOLDERS_FEE = 600;
    uint constant public DENOMINATOR_FEE = 1000;
}