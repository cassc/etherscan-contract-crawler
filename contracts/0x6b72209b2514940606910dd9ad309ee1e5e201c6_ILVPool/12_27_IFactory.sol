// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { ICorePool } from "./ICorePool.sol";

interface IFactory {
    function owner() external view returns (address);

    function ilvPerSecond() external view returns (uint192);

    function totalWeight() external view returns (uint32);

    function secondsPerUpdate() external view returns (uint32);

    function endTime() external view returns (uint32);

    function lastRatioUpdate() external view returns (uint32);

    function pools(address _poolToken) external view returns (ICorePool);

    function poolExists(address _poolAddress) external view returns (bool);

    function getPoolAddress(address poolToken) external view returns (address);

    function getPoolData(address _poolToken)
        external
        view
        returns (
            address,
            address,
            uint32,
            bool
        );

    function shouldUpdateRatio() external view returns (bool);

    function registerPool(ICorePool pool) external;

    function updateILVPerSecond() external;

    function mintYieldTo(
        address _to,
        uint256 _value,
        bool _useSILV
    ) external;

    function changePoolWeight(address pool, uint32 weight) external;
}