// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

interface ILender {
    function batch(
        bytes[] calldata c
    ) external payable returns (bytes[] memory results);

    function approve(address, uint256, address) external returns (bool);
}