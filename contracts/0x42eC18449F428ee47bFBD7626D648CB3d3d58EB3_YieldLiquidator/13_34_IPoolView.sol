//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IPool} from "@yield-protocol/yieldspace-tv/src/interfaces/IPool.sol";

interface IPoolView {
    function maxFYTokenOut(IPool pool) external view returns (uint128);
}