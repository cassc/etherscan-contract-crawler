// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IGTokenFactory {
    function deployGToken(
        address spToken,
        address liquidator,
        address tokenMarket,
        address govAdminRegistry
    ) external returns (address);
}