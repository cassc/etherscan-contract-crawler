// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

contract Events {
    /// Emitted whenever a user withdraws assets and a fee is collected.
    event LogWithdrawFeeCollected(address indexed payer, uint256 indexed fee);

    /// Emitted whenever a user imports his old Eth vault position.
    event LogImportV1ETHVault(
        address indexed receiver,
        uint256 indexed iTokenAmount,
        uint256 indexed route,
        uint256 deleverageWethAmount,
        uint256 withdrawStETHAmount,
        uint256 userNetDeposit
    );

    /// Emitted whenever rebalancer refinances between 2 protocols.
    event LogCollectRevenue(uint256 amount, address indexed to);

    /// Emitted whenever exchange price is updated.
    event LogUpdateExchangePrice(
        uint256 indexed exchangePriceBefore,
        uint256 indexed exchangePriceAfter
    );
}