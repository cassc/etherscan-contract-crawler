// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IERC20Receiver {
    function onReceiveERC20(
        address token,
        address from,
        uint256 amount
    ) external;
}