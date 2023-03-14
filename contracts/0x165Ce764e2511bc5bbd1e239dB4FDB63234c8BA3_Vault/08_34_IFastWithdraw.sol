// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./ISwapData.sol";

struct FastWithdrawParams {
    bool doExecuteWithdraw;
    uint256[][] slippages;
    SwapData[][] swapData;
}

interface IFastWithdraw {
    function transferShares(
        address[] calldata vaultStrategies,
        uint128[] calldata sharesWithdrawn,
        uint256 proportionateDeposit,
        address user,
        FastWithdrawParams calldata fastWithdrawParams
    ) external;

        /* ========== EVENTS ========== */

    event StrategyWithdrawn(address indexed user, address indexed vault, address indexed strategy);
    event UserSharesSaved(address indexed user, address indexed vault);
    event FastWithdrawExecuted(address indexed user, address indexed vault, uint256 totalWithdrawn);
}