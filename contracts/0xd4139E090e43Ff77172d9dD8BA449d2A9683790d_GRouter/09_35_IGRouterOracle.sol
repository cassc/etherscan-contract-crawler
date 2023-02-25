// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

interface IGRouterOracle {
    function stableToUsd(uint256 _amount, uint256 _index)
        external
        view
        returns (uint256, bool);

    function usdToStable(uint256 _amount, uint256 _index)
        external
        view
        returns (uint256, bool);
}