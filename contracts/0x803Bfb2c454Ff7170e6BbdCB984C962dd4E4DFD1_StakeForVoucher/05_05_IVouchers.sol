// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IVouchers{
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}