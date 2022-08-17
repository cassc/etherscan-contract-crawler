// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IRegistry {
    function get_virtual_price_from_lp_token(address)
        external
        view
        returns (uint256);
}