// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.17;

interface IVault {
    function transferFromVault(
        address to,
        uint256 amountInWei
    ) external returns (bool);
}