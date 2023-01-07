// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {ILevelOracle} from "../interfaces/ILevelOracle.sol";
import {ILPToken} from "../interfaces/ILPToken.sol";
import {IPoolHook} from "../interfaces/IPoolHook.sol";

// common precision for fee, tax, interest rate, maintenace margin ratio
uint256 constant PRECISION = 1e10;
uint256 constant LP_INITIAL_PRICE = 1e12; // fix to 1$
uint256 constant MAX_BASE_SWAP_FEE = 1e8; // 1%
uint256 constant MAX_TAX_BASIS_POINT = 1e8; // 1%
uint256 constant MAX_POSITION_FEE = 1e8; // 1%
uint256 constant MAX_LIQUIDATION_FEE = 10e30; // 10$
uint256 constant MAX_TRANCHES = 3;
uint256 constant MAX_ASSETS = 10;
uint256 constant MAX_INTEREST_RATE = 1e7; // 0.1%
uint256 constant MAX_MAINTENANCE_MARGIN = 5e8; // 5%

struct Fee {
    /// @notice charge when changing position size
    uint256 positionFee;
    /// @notice charge when liquidate position (in dollar)
    uint256 liquidationFee;
    /// @notice swap fee used when add/remove liquidity, swap token
    uint256 baseSwapFee;
    /// @notice tax used to adjust swapFee due to the effect of the action on token's weight
    /// It reduce swap fee when user add some amount of a under weight token to the pool
    uint256 taxBasisPoint;
    /// @notice swap fee used when add/remove liquidity, swap token
    uint256 stableCoinBaseSwapFee;
    /// @notice tax used to adjust swapFee due to the effect of the action on token's weight
    /// It reduce swap fee when user add some amount of a under weight token to the pool
    uint256 stableCoinTaxBasisPoint;
    /// @notice part of fee will be kept for DAO, the rest will be distributed to pool amount, thus
    /// increase the pool value and the price of LP token
    uint256 daoFee;
}

struct Position {
    /// @dev contract size is evaluated in dollar
    uint256 size;
    /// @dev collateral value in dollar
    uint256 collateralValue;
    /// @dev contract size in indexToken
    uint256 reserveAmount;
    /// @dev average entry price
    uint256 entryPrice;
    /// @dev last cumulative interest rate
    uint256 borrowIndex;
}

struct PoolTokenInfo {
    /// @notice amount reserved for fee
    uint256 feeReserve;
    /// @notice recorded balance of token in pool
    uint256 poolBalance;
    /// @notice last borrow index update timestamp
    uint256 lastAccrualTimestamp;
    /// @notice accumulated interest rate
    uint256 borrowIndex;
    /// @notice average entry price of all short position
    /// @deprecated avg short price must be calculate per tranche
    uint256 averageShortPrice;
}

struct AssetInfo {
    /// @notice amount of token deposited (via add liquidity or increase long position)
    uint256 poolAmount;
    /// @notice amount of token reserved for paying out when user decrease long position
    uint256 reservedAmount;
    /// @notice total borrowed (in USD) to leverage
    uint256 guaranteedValue;
    /// @notice total size of all short positions
    uint256 totalShortSize;
}

abstract contract PoolStorage {
    Fee public fee;

    address public feeDistributor;

    ILevelOracle public oracle;

    address public orderManager;

    // ========= Assets management =========
    mapping(address => bool) public isAsset;
    /// @notice A list of all configured assets
    /// @dev use a pseudo address for ETH
    /// Note that token will not be removed from this array when it was delisted. We keep this
    /// list to calculate pool value properly
    address[] public allAssets;

    mapping(address => bool) public isListed;

    mapping(address => bool) public isStableCoin;

    mapping(address => PoolTokenInfo) public poolTokens;

    /// @notice target weight for each tokens
    mapping(address => uint256) public targetWeights;

    mapping(address => bool) public isTranche;
    /// @notice risk factor of each token in each tranche
    /// @dev token => tranche => risk factor
    mapping(address => mapping(address => uint256)) public riskFactor;
    /// @dev token => total risk score
    mapping(address => uint256) public totalRiskFactor;

    address[] public allTranches;
    /// @dev tranche => token => asset info
    mapping(address => mapping(address => AssetInfo)) public trancheAssets;
    /// @notice position reserve in each tranche
    mapping(address => mapping(bytes32 => uint256)) public tranchePositionReserves;

    /// @notice interest rate model
    uint256 public interestRate;

    uint256 public accrualInterval;

    uint256 public totalWeight;
    // ========= Positions management =========
    /// @notice max leverage for each token
    uint256 public maxLeverage;
    /// @notice positions tracks all open positions
    mapping(bytes32 => Position) public positions;

    IPoolHook public poolHook;

    uint256 public maintenanceMargin;

    uint256 public addRemoveLiquidityFee;

    mapping(address => mapping(address => uint)) public averageShortPrices;
}