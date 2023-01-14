// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IERC20Detailed
 * @dev IERC20Detailed interface
 **/

interface IERC20Detailed {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}