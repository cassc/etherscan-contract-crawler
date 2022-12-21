// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IRedeemerFactory {
    function createRedeemerContract(
        address fluentToken,
        address burnerContract,
        address fedMember,
        address redeemersBookkeper,
        address redeemersTreasury
    ) external returns (address);
}