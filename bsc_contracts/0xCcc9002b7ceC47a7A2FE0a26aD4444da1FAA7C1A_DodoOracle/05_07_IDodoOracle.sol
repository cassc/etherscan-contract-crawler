//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IDodoOracle {
    // Must return 1e18 value
    function prices(address base_) external view returns (uint256 price);
}