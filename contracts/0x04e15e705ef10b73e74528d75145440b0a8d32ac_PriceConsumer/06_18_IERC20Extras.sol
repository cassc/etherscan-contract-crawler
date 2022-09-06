// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IERC20Extras {
    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}