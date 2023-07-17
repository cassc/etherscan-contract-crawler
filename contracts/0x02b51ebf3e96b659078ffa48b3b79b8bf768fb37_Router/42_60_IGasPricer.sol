// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

interface IGasPricer {
    function getGasPriceTokenOutRAY(address token)
        external
        view
        returns (uint256 gasPrice);
}