// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

interface ISatelliteEMPIRE {
    function unlock(address to, uint256 amount) external;
    function lock(address from, uint256 amount) external;
}