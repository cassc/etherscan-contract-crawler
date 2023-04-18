// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract MockGaugeV2 {
    mapping(address => uint256) integrate;

    function integrateFraction(address addr) external view returns (uint256) {
        return integrate[addr];
    }

    function userCheckpoint(address addr) external returns (bool) {
        integrate[addr] += 100 * 1e18;

        return true;
    }
}