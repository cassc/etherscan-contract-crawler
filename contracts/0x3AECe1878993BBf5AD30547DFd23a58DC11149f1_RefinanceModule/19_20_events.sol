// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

contract Events {
    /// @notice Emitted whenever rebalancer refinances between 2 protocols.
    event LogRefinance(
        uint8 indexed protocolFrom,
        uint8 indexed protocolTo,
        uint256 indexed route,
        uint256 wstETHflashAmount,
        uint256 wETHBorrowAmount,
        uint256 withdrawAmount
    );
}