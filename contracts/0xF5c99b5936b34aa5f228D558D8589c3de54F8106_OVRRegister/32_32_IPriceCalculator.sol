// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IPriceCalculator {
    function valueOfAsset(uint256 amount)
        external
        view
        returns (uint256 valueInUSD);
}