// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

import "./IExchangeManager.sol";

interface IUnipilot {
    struct DepositVars {
        uint256 totalAmount0;
        uint256 totalAmount1;
        uint256 totalLiquidity;
        uint256 shares;
    }

    event ExchangeWhitelisted(address newExchange);
    event ExchangeStatus(address exchange, bool status);
    event GovernanceUpdated(address oldGovernance, address newGovernance);

    function governance() external view returns (address);

    function mintProxy() external view returns (address);

    function mintPilot(address recipient, uint256 amount) external;

    function deposit(
        IExchangeManager.DepositParams memory params,
        bytes memory data
    ) external payable returns (uint256 amount0Added, uint256 amount1Added);

    function createPoolAndDeposit(
        IExchangeManager.DepositParams memory params,
        bytes[2] calldata data
    )
        external
        payable
        returns (
            uint256 amount0Added,
            uint256 amount1Added,
            uint256 mintedTokenId
        );

    function exchangeManagerWhitelist(address exchange)
        external
        view
        returns (bool);

    function withdraw(
        IExchangeManager.WithdrawParams calldata params,
        bytes memory data
    ) external payable;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}