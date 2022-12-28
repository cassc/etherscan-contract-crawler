//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IIFlashLoan {
    function _flashLoan(
        IERC20 asset,
        uint256 amount,
        bytes memory data
    ) external;

    function _repayFlashLoan(IERC20 token, uint256 amount) external;
}

interface IIExchange {
    function _exchange(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) external returns (uint256);
}

interface IIOracle {
    function _getPrice(IERC20 token) external view returns (uint256);
}

interface IIProtocol {
    function collateralAmount(IERC20 token) external returns (uint256);

    function borrowAmount(IERC20 token) external returns (uint256);

    function pnl(
        IERC20 collateral,
        IERC20 debt,
        uint256 leverageRatio
    ) external returns (uint256);

    function _pnl(IERC20 collateral, IERC20 debt) external returns (uint256);

    function _deposit(IERC20 token, uint256 amount) external;

    function _redeem(IERC20 token, uint256 amount) external;

    function _redeemAll(IERC20 token) external;

    function _borrow(IERC20 token, uint256 amount) external;

    function _repay(IERC20 token, uint256 amount) external;
}

interface IHolder is IIFlashLoan, IIExchange, IIProtocol {
    function stopLoss() external view returns (uint256);

    function takeProfit() external view returns (uint256);

    function pnl(
        IERC20 collateral,
        IERC20 debt,
        uint256 leverageRatio
    ) external returns (uint256);

    function openPosition(
        IERC20 collateral,
        IERC20 debt,
        uint256 amount,
        uint256 leverageRatio,
        uint256 stopLossValue,
        uint256 takeProfitValue,
        SharedStructs.OneInchParams memory inch
    ) external payable returns (uint256);

    function closePosition(
        IERC20 collateral,
        IERC20 debt,
        address user,
        SharedStructs.OneInchParams memory inch
    ) external;
}

library SharedStructs {
    struct OneInchParams {
        bytes prefix;
        bytes postfix;
    }
}