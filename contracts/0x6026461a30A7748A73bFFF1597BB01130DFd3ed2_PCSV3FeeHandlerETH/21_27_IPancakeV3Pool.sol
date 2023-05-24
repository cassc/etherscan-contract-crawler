// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.10;

interface IPancakeV3Pool {
    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function fee() external view returns (uint24);

    // accumulated protocol fees in token0/token1 units
    struct ProtocolFees {
        uint128 token0;
        uint128 token1;
    }
    function protocolFees() external view returns (ProtocolFees memory fee);

    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}