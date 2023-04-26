// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IPool} from "@maverickprotocol/maverick-v1-interfaces/contracts/interfaces/IPool.sol";

import {PoolPositionDynamicSlim} from "../PoolPositionDynamicSlim.sol";
import {IPoolPositionSlim} from "../interfaces/IPoolPositionSlim.sol";

library PoolPositionDynamicDeployerSlim {
    function deploy(IPool _pool, uint128[] memory _binIds, uint128[] memory _ratios, uint256 factoryCount) external returns (IPoolPositionSlim) {
        return new PoolPositionDynamicSlim(_pool, _binIds, _ratios, factoryCount);
    }
}