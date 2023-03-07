// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.16;

struct GasFee {
    uint256 amount;
    address token;
    address collector;
}

interface IGasVendor {
    function getGasFee(address msgSender, bytes calldata msgData) external returns (GasFee memory);
}