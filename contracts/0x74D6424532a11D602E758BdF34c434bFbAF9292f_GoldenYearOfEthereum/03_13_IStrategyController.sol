// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '../Util.sol';

interface IStrategyController {
    function getCurrentTax() external view returns (Util.Tax memory, Util.Tax memory);
}