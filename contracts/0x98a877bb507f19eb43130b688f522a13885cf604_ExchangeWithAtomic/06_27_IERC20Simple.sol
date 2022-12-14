// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

interface IERC20Simple {
    function decimals() external view virtual returns (uint8);
}