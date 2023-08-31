// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { ICorePool } from "./ICorePool.sol";

interface IILVPool is ICorePool {
    function stakeAsPool(address _staker, uint256 _value) external;
}