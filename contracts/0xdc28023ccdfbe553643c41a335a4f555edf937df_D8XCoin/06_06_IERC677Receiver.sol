// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC677Receiver {
    function onTokenTransfer(
        address from,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}