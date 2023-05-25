// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IPancakeV3Pool.sol";
import "./ILMPool.sol";

interface ILMPoolDeployer {
    function deploy(IPancakeV3Pool pool) external returns (ILMPool lmPool);
}