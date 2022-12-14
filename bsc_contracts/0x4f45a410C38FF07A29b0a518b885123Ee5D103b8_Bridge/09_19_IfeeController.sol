// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.2;

interface IfeeController {
    function getBridgeFee(address sender, address assetAddress)
        external
        view
        returns (uint256);
}