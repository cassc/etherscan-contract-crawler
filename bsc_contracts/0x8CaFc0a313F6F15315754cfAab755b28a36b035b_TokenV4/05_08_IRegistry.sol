//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IRegistry {
    function registerTransfer(
        address from,
        address to,
        uint256 amount
    ) external;

    function isAmmPair(address addr) external view returns (bool);
}