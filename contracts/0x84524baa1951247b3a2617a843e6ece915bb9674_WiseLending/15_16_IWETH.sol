// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.21;

import "./IERC20.sol";

interface IWETH is IERC20 {

    function deposit()
        external
        payable;

    function withdraw(
        uint256
    )
        external;
}