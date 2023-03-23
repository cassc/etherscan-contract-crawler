// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "./interfaces/LPoolInterface.sol";
import "./interfaces/OpenLevInterface.sol";
import "./interfaces/ControllerInterface.sol";
import "./interfaces/DexAggregatorInterface.sol";
import "./interfaces/XOLEInterface.sol";
import "./interfaces/OPBuyBackInterface.sol";

contract OPBorrowingStorage {
    event NewMarket(uint16 marketId, LPoolInterface pool0, LPoolInterface pool1, address token0, address token1, uint32 dex, uint token0Liq, uint token1Liq);

    event Borrow(address indexed borrower, uint16 marketId, bool collateralIndex, uint collateral, uint borrow, uint borrowFees);

    event Repay(address indexed borrower, uint16 marketId, bool collateralIndex, uint repayAmount, uint collateral);

    event Redeem(address indexed borrower, uint16 marketId, bool collateralIndex, uint collateral);

    event Liquidate(
        address indexed borrower,
        uint16 marketId,
        bool collateralIndex,
        address liquidator,
        uint collateralDecrease,
        uint repayAmount,
        uint outstandingAmount,
        uint liquidateFees,
        uint token0Price
    );

    event NewLiquidity(uint16 marketId, uint oldToken0Liq, uint oldToken1Liq, uint newToken0Liq, uint newToken1Liq);

    event NewMarketConf(
        uint16 marketId,
        uint16 collateralRatio,
        uint16 maxLiquidityRatio,
        uint16 borrowFeesRatio,
        uint16 insuranceRatio,
        uint16 poolReturnsRatio,
        uint16 liquidateFeesRatio,
        uint16 liquidatorReturnsRatio,
        uint16 liquidateInsuranceRatio,
        uint16 liquidatePoolReturnsRatio,
        uint16 liquidateMaxLiquidityRatio,
        uint16 twapDuration
    );

    struct Market {
        LPoolInterface pool0; // pool0 address
        LPoolInterface pool1; // pool1 address
        address token0; // token0 address
        address token1; // token1 address
        uint32 dex; // decentralized exchange
    }

    struct MarketConf {
        uint16 collateralRatio; //  the collateral ratio, 6000 => 60%
        uint16 maxLiquidityRatio; // the maximum pool's total borrowed cannot be exceeded dex liquidity*ratio, 1000 => 10%
        uint16 borrowFeesRatio; // the borrowing fees ratio, 30 => 0.3%
        uint16 insuranceRatio; // the insurance percentage of the borrowing fees, 3000 => 30%
        uint16 poolReturnsRatio; // the pool's returns percentage of the borrowing fees, 3000 => 30%
        uint16 liquidateFeesRatio; // the liquidation fees ratio, 100 => 1%
        uint16 liquidatorReturnsRatio; // the liquidator returns percentage of the liquidation fees, 3000 => 30%
        uint16 liquidateInsuranceRatio; // the insurance percentage of the liquidation fees, 3000 => 30%
        uint16 liquidatePoolReturnsRatio; // the pool's returns percentage of the liquidation fees, 3000 => 30%
        uint16 liquidateMaxLiquidityRatio; // the maximum liquidation amount cannot be exceeded dex liquidity*ratio, 1000=> 10%
        uint16 twapDuration; // the TWAP duration, 60 => 60s
    }

    struct Liquidity {
        uint token0Liq; // the token0 liquidity
        uint token1Liq; // the token1 liquidity
    }

    struct Insurance {
        uint insurance0; // the token0 insurance
        uint insurance1; // the token1 insurance
    }

    struct LiquidationConf {
        uint128 liquidatorXOLEHeld; //  the minimum amount of xole held by liquidator
        uint8 priceDiffRatio; // the maximum ratio of real price diff TWAP, 10 => 10%
        OPBuyBackInterface buyBack; // the ole buyback contract address
    }

    uint internal constant RATIO_DENOMINATOR = 10000;

    address public immutable wETH;

    OpenLevInterface public immutable openLev;

    ControllerInterface public immutable controller;

    DexAggregatorInterface public immutable dexAgg;

    XOLEInterface public immutable xOLE;

    // mapping of marketId to market info
    mapping(uint16 => Market) public markets;

    // mapping of marketId to market config
    mapping(uint16 => MarketConf) public marketsConf;

    // mapping of borrower, marketId, collateralIndex to collateral shares
    mapping(address => mapping(uint16 => mapping(bool => uint))) public activeCollaterals;

    // mapping of marketId to insurances
    mapping(uint16 => Insurance) public insurances;

    // mapping of marketId to time weighted average liquidity
    mapping(uint16 => Liquidity) public twaLiquidity;

    // mapping of token address to total shares
    mapping(address => uint) public totalShares;

    MarketConf public marketDefConf;

    LiquidationConf public liquidationConf;

    constructor(OpenLevInterface _openLev, ControllerInterface _controller, DexAggregatorInterface _dexAgg, XOLEInterface _xOLE, address _wETH) {
        openLev = _openLev;
        controller = _controller;
        dexAgg = _dexAgg;
        xOLE = _xOLE;
        wETH = _wETH;
    }
}

interface IOPBorrowing {
    function initialize(OPBorrowingStorage.MarketConf memory _marketDefConf, OPBorrowingStorage.LiquidationConf memory _liquidationConf) external;

    // only controller
    function addMarket(uint16 marketId, LPoolInterface pool0, LPoolInterface pool1, bytes memory dexData) external;

    /*** Borrower Functions ***/
    function borrow(uint16 marketId, bool collateralIndex, uint collateral, uint borrowing) external payable;

    function repay(uint16 marketId, bool collateralIndex, uint repayAmount, bool isRedeem) external payable returns (uint redeemShare);

    function redeem(uint16 marketId, bool collateralIndex, uint collateral) external;

    function liquidate(uint16 marketId, bool collateralIndex, address borrower) external;

    function collateralRatio(uint16 marketId, bool collateralIndex, address borrower) external view returns (uint current);

    /*** Admin Functions ***/
    function migrateOpenLevMarkets(uint16 from, uint16 to) external;

    function setTwaLiquidity(uint16[] calldata marketIds, OPBorrowingStorage.Liquidity[] calldata liquidity) external;

    function setMarketConf(uint16 marketId, OPBorrowingStorage.MarketConf calldata _marketConf) external;

    function setMarketDex(uint16 marketId, uint32 dex) external;

    function moveInsurance(uint16 marketId, bool tokenIndex, address to, uint moveShare) external;
}