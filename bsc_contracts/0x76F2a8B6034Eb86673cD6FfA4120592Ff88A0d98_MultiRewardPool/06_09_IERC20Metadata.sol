//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/IERC20.sol";

interface IERC20Metadata is IERC20 {
    function decimals() external view returns (uint8);
}