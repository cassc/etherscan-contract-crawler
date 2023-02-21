// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

contract Events {
    /// Emitted whenever a protocol is leveraged.
    event LogLeverage(
        uint8 indexed protocol,
        uint256 indexed route,
        uint256 wstETHflashAmt,
        uint256 ethAmountBorrow,
        address[] vaults,
        uint256[] vaultAmts,
        uint256 indexed swapMode,
        uint256 unitAmt,
        uint256 vaultSwapAmt
    );
}