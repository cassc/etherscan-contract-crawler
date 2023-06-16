// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IHarvestableStrategy {
    function harvest() external;

    function controller() external view returns (address);

    function want() external view returns (address);
}