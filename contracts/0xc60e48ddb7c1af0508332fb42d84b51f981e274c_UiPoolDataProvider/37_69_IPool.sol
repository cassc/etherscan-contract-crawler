// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPoolCore} from "./IPoolCore.sol";
import {IPoolMarketplace} from "./IPoolMarketplace.sol";
import {IPoolParameters} from "./IPoolParameters.sol";
import {IParaProxyInterfaces} from "./IParaProxyInterfaces.sol";
import {IPoolPositionMover} from "./IPoolPositionMover.sol";
import "./IPoolApeStaking.sol";

/**
 * @title IPool
 *
 * @notice Defines the basic interface for an ParaSpace Pool.
 **/
interface IPool is
    IPoolCore,
    IPoolMarketplace,
    IPoolParameters,
    IPoolApeStaking,
    IParaProxyInterfaces,
    IPoolPositionMover
{

}