// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/**
* @title Interface that can be used to interact with the AveragePriceOracle contract.
*/
interface IAveragePriceOracle {
    function update() external;
    function twapLast() external view returns (uint256);
}