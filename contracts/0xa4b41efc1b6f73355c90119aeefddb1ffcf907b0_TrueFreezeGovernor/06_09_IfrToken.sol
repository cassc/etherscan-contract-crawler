//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "IERC20.sol";

interface IfrToken is IERC20 {
    function mint(address, uint256) external;

    function burn(address, uint256) external;
}