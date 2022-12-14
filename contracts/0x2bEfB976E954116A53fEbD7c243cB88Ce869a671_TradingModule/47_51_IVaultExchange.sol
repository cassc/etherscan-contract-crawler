// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

import "./ITradingModule.sol";

struct VaultExchange {
    TradeType tradeType;
    address sellToken;
    address buyToken;
    uint256 amount;
    uint256 limit;
}

interface IVaultExchangeCallback {
    function exchangeCallback(address token, uint256 amount) external;
}

interface IVaultExchange {
    function executeTrade(uint16 dexId, Trade calldata trade)
        external
        returns (uint256 amountSold, uint256 amountBought);

    function exchange(VaultExchange calldata request)
        external
        returns (uint256 amountSold, uint256 amountBought);
}