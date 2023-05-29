// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import 'src/lib/Pendle.sol';

interface IPendle {
    function swapExactTokenForPt(
        address,
        address,
        uint256,
        Pendle.ApproxParams calldata,
        Pendle.TokenInput calldata
    ) external returns (uint256, uint256);
}