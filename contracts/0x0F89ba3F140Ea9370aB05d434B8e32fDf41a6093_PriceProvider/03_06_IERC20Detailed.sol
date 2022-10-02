// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

interface IERC20Detailed {

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);
}