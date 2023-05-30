// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

abstract contract ComptrollerExInterface {
    function liquidateCalculateSeizeTokensEx(
        address cTokenBorrowed,
        address cTokenExCollateral,
        uint repayAmount) external virtual returns (uint, uint, uint);
}