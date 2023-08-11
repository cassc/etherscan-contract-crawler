// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.21;

interface IWstETH {

    function getStETHByWstETH(
        uint256 _wstETHAmount
    )
        external
        view
        returns (uint256);

    function decimals()
        external
        view
        returns (uint8);
}