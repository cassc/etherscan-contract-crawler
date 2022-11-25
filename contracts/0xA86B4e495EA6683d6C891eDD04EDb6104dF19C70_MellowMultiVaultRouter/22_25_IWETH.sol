// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "../interfaces/IERC20Minimal.sol";

interface IWETH is IERC20Minimal {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}