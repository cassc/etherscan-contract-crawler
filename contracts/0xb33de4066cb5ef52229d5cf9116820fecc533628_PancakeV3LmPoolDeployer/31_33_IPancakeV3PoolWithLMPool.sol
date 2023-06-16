// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
import '@pancakeswap/v3-core/contracts/interfaces/IPancakeV3Pool.sol';

interface IPancakeV3PoolWithLMPool is IPancakeV3Pool {
    function lmPool() external view returns (address);
}