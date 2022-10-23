// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {IERC20} from 'isolmate/interfaces/tokens/IERC20.sol';

interface IPairManager is IERC20 {
    function mint(uint256 amount0Desired, uint256 amount1Desired, uint256 amount0Min, uint256 amount1Min, address to)
        external
        returns (uint128 liquidity);
}

interface IKeep3r {
    function addJob(address) external;

    function isKeeper(address) external returns (bool);

    function worked(address) external;

    function bond(address, uint256) external;

    function activate(address) external;

    function liquidityAmount(address, address) external view returns (uint256);

    function addLiquidityToJob(address, address, uint256) external;

    function unbondLiquidityFromJob(address, address, uint256) external;

    function withdrawLiquidityFromJob(address, address, address) external;
}