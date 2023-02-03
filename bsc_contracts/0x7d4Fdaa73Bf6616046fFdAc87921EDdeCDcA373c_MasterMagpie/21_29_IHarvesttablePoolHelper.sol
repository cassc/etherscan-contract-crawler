// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPoolHelper.sol";


interface IHarvesttablePoolHelper is IPoolHelper {
    function harvest() external;
}