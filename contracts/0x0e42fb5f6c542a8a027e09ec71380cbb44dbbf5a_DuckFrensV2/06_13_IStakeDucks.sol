// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IStakeDucks {
    function depositsOf(address account)
        external
        view
        returns (uint256[] memory);
}