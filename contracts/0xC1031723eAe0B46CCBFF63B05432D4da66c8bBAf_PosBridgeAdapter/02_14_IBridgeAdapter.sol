// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.8.0;

interface IBridgeAdapter {
    function sendAssets(uint256 value, address to, uint8 slippage) external returns (bytes32 transferId);
}