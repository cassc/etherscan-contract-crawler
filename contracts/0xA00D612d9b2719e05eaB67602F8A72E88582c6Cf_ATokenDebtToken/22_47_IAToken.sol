// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import {IPool} from "./IPool.sol";

/************
@title IAToken interface
@notice Interface for rebasing AToken support.*/

interface IAToken {
    function POOL() external view returns (IPool pool);

    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}