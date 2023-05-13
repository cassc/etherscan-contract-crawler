// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IHLPClaimPool {
    function project() external view returns (address);

    function registerProject() external;
}