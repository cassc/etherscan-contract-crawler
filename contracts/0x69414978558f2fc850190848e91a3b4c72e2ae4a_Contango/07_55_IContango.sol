//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc7399/IERC7399.sol";

import "../core/PositionNFT.sol";
import "../interfaces/IContango.sol";
import "../interfaces/IFeeManager.sol";
import "../interfaces/IVault.sol";
import "../libraries/DataTypes.sol";
import "../moneymarkets/interfaces/IUnderlyingPositionFactory.sol";

struct SwapInfo {
    Currency inputCcy;
    int256 input;
    int256 output;
    uint256 price; // in quote currency
}

struct Trade {
    int256 quantity;
    SwapInfo swap;
    Currency cashflowCcy;
    int256 cashflow; // negative when removing from position, positive otherwise
    uint256 fee;
    Currency feeCcy;
    uint256 forwardPrice;
}

struct TradeParams {
    PositionId positionId; // existing position or a new one when coded with number 0 (see ../libraries/DataTypes.sol and test/Encoder.sol)
    int256 quantity;
    uint256 limitPrice; // in quote currency
    Currency cashflowCcy;
    int256 cashflow;
}

struct ExecutionParams {
    address spender;
    address router;
    uint256 swapAmount;
    bytes swapBytes;
    IERC7399 flashLoanProvider;
}

struct Instrument {
    IERC20 base;
    uint256 baseUnit; // e.g. WETH: 1e18
    IERC20 quote;
    uint256 quoteUnit; // e.g. USDC: 1e6
    bool closingOnly;
}

interface IContangoEvents {

    event PositionUpserted(
        PositionId indexed positionId,
        address indexed owner,
        address indexed tradedBy,
        Currency cashflowCcy,
        int256 cashflow,
        int256 quantityDelta,
        uint256 price,
        uint256 fee,
        Currency feeCcy
    );

    event ClosingOnlySet(Symbol indexed symbol, bool closingOnly);
    event InstrumentCreated(Symbol indexed symbol, IERC20 base, IERC20 quote);
    event MoneyMarketRegistered(MoneyMarketId indexed id, IMoneyMarket moneyMarket);

}

interface IContangoErrors {

    error CashflowCcyRequired(); // 0x2bed762a
    error ClosingOnly(); // 0x1dacbd6f
    error ExcessiveInputQuote(uint256 limit, uint256 actual); // 0x937d5fee
    error InsufficientBaseOnOpen(uint256 expected, int256 actual); // 0x49cb41d9
    error InsufficientBaseCashflow(int256 expected, int256 actual); // 0x0ef42287
    error InstrumentAlreadyExists(Symbol symbol); // 0x6170624c
    error InvalidInstrument(Symbol symbol); // 0x2d5bccd2
    error NotFlashBorrowProvider(address msgSender); // 0x50459441
    error OnlyFullClosureAllowedAfterExpiry(); // 0x62a73c9a
    error PriceAboveLimit(uint256 limit, uint256 actual); // 0x6120c45f
    error PriceBelowLimit(uint256 limit, uint256 actual); // 0x756cfc28
    error UnexpectedCallback(); // 0xdab1e993
    error InvalidCashflowCcy(); // 0x2c6ff311
    error UnexpectedTrade(); // 0xf1a9b64c

}

interface IContango is IContangoEvents, IContangoErrors {

    function trade(TradeParams calldata tradeParams, ExecutionParams calldata execParams)
        external
        payable
        returns (PositionId positionId, Trade memory trade);

    function tradeOnBehalfOf(TradeParams calldata tradeParams, ExecutionParams calldata execParams, address onBehalfOf)
        external
        payable
        returns (PositionId positionId, Trade memory trade);

    function claimRewards(PositionId positionId, address to) external;

    // ======== View ========

    function positionFactory() external view returns (IUnderlyingPositionFactory);
    function instrument(Symbol symbol) external view returns (Instrument memory);
    function positionNFT() external view returns (PositionNFT);
    function vault() external view returns (IVault);
    function feeManager() external view returns (IFeeManager);

    // ======== Admin ========

    function createInstrument(Symbol symbol, IERC20 base, IERC20 quote) external;
    function setClosingOnly(Symbol symbol, bool closingOnly) external;
    function pause() external;
    function unpause() external;

    // ======== Callbacks ========

    function completeClose(address initiator, address repayTo, address asset, uint256 amount, uint256 fee, bytes calldata params)
        external
        returns (bytes memory result);

    function completeOpenFromFlashLoan(
        address initiator,
        address repayTo,
        address asset,
        uint256 amount,
        uint256 fee,
        bytes calldata params
    ) external returns (bytes memory result);

    function completeOpenFromFlashBorrow(IERC20 asset, uint256 amountOwed, bytes calldata params) external returns (bytes memory result);

}