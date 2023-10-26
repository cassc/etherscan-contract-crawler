// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.8.0;

interface ICrossLedgerVault {
    function transferCompleted(bytes32 transferId, uint256 value, uint8 slippage) external;
    function mainAsset() external view returns (address);
}