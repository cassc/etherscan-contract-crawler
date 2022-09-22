//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IVspOracle.sol";

/**
 * @title MockOracle contract
 */
contract MockOracle is IVspOracle {
    function update() external {}

    function getPriceInUsd(address token_) external pure returns (uint256 _priceInUsd) {
        return (0.5e18);
    }
}