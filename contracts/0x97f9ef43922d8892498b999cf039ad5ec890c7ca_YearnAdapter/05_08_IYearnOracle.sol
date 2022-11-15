// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IYearnOracle {
    function getPriceUsdcRecommended(address tokenAddress) external view returns (uint256);
}
