// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IConvex {
    function get_virtual_price()
        external
        view
        returns (uint256);
}