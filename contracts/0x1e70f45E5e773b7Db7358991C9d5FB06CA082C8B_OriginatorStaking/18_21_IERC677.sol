// SPDX-License-Identifier: gpl-3.0

pragma solidity 0.7.5;

interface IERC677 {
    function transferAndCall(
        address to,
        uint256 value,
        bytes memory data
    ) external returns (bool ok);

    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
}