// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ICurveGauge {
    function is_killed() external view returns(bool);
}