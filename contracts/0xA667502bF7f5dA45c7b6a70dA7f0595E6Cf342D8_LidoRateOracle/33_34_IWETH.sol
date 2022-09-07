// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "../interfaces/IERC20Minimal.sol";

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}