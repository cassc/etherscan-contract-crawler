// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IERC677 {
    event ERC677Transfer(address from, address receiver, uint256 amount, bytes data);

    function transferAndCall(
        address receiver,
        uint256 amount,
        bytes memory data
    ) external returns (bool success);
}