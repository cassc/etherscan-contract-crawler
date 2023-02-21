// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../dependencies/@openzeppelin/token/ERC20/IERC20.sol";

interface IMET is IERC20 {
    function delegate(address) external;
}