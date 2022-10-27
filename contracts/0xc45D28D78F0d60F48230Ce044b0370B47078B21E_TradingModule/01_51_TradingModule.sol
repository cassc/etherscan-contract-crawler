// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import {Deployments} from "../global/Deployments.sol";
import {Constants} from "../global/Constants.sol";
import {BalancerV2Adapter} from "./adapters/BalancerV2Adapter.sol";
import {CurveAdapter} from "./adapters/CurveAdapter.sol";
import {UniV2Adapter} from "./adapters/UniV2Adapter.sol";
import {UniV3Adapter} from "./adapters/UniV3Adapter.sol";
import {ZeroExAdapter} from "./adapters/ZeroExAdapter.sol";
import {TradingUtils} from "./TradingUtils.sol";

import {IERC20} from "../utils/TokenUtils.sol";
import {NotionalProxy} from "../../interfaces/notional/NotionalProxy.sol";
import {ITradingModule} from "../../interfaces/trading/ITradingModule.sol";
import "../../interfaces/trading/IVaultExchange.sol";
import "../../interfaces/chainlink/AggregatorV2V3Interface.sol";

/// @notice TradingModule is meant to be an upgradeable contract deployed to help Strategy Vaults
/// exchange tokens via multiple DEXes as well as receive price oracle information
contract TradingModule is Initializable, UUPSUpgradeable, ITradingModule {
    NotionalProxy public immutable NOTIONAL;
    // Used to get the proxy address inside delegate call contexts
    ITradingModule internal immutable PROXY;

    error SellTokenEqualsBuyToken();
    error UnknownDEX();
    error InsufficientPermissions();

    struct PriceOracle {
        AggregatorV2V3Interface oracle;
        uint8 rateDecimals;
    }

    int256 internal constant RATE_DECIMALS = 1e18;
    mapping(address => PriceOracle) public priceOracles;
    uint32 public maxOracleFreshnessInSeconds;
    mapping(address => mapping(address => TokenPermissions)) public tokenWhitelist;

    constructor(NotionalProxy notional_, ITradingModule proxy_) initializer { 
        NOTIONAL = notional_;
        PROXY = proxy_;
    }

    modifier onlyNotionalOwner() {
        require(msg.sender == NOTIONAL.owner());
        _;
    }

    function _authorizeUpgrade(
        address /* newImplementation */
    ) internal override onlyNotionalOwner {}

    function initialize(uint32 maxOracleFreshnessInSeconds_) external initializer onlyNotionalOwner {
        maxOracleFreshnessInSeconds = maxOracleFreshnessInSeconds_;
    }

    function setMaxOracleFreshness(uint32 newMaxOracleFreshnessInSeconds) external onlyNotionalOwner {
        emit MaxOracleFreshnessUpdated(maxOracleFreshnessInSeconds, newMaxOracleFreshnessInSeconds);
        maxOracleFreshnessInSeconds = newMaxOracleFreshnessInSeconds;
    }

    function setPriceOracle(address token, AggregatorV2V3Interface oracle) external override onlyNotionalOwner {
        PriceOracle storage oracleStorage = priceOracles[token];
        oracleStorage.oracle = oracle;
        oracleStorage.rateDecimals = oracle.decimals();

        emit PriceOracleUpdated(token, address(oracle));
    }

    function setTokenPermissions(
        address sender, 
        address token, 
        TokenPermissions calldata permissions
    ) external override onlyNotionalOwner {
        /// @dev update these if we are adding new DEXes or types
        for (uint32 i = uint32(DexId.NOTIONAL_VAULT) + 1; i < 32; i++) {
            require(!_hasPermission(permissions.dexFlags, uint32(1 << i)));
        }
        for (uint32 i = uint32(TradeType.EXACT_OUT_BATCH) + 1; i < 32; i++) {
            require(!_hasPermission(permissions.tradeTypeFlags, uint32(1 << i)));
        }
        tokenWhitelist[sender][token] = permissions;
        emit TokenPermissionsUpdated(sender, token, permissions);
    }

    /// @notice Called to receive execution data for vaults that will execute trades without
    /// delegating calls to this contract
    /// @param dexId enum representing the id of the dex
    /// @param from address for the contract executing the trade
    /// @param trade trade object
    /// @return spender the address to approve for the soldToken, will be address(0) if the
    /// send token is ETH and therefore does not require approval
    /// @return target contract to execute the call against
    /// @return msgValue amount of ETH to transfer to the target, if any
    /// @return executionCallData encoded call data for the trade
    function getExecutionData(
        uint16 dexId,
        address from,
        Trade calldata trade
    )
        external
        view
        override
        returns (
            address spender,
            address target,
            uint256 msgValue,
            bytes memory executionCallData
        )
    {
        return _getExecutionData(dexId, from, trade);
    }

    /// @notice Executes a trade with a dynamic slippage limit based on chainlink oracles.
    /// @dev Expected to be called via delegatecall on the implementation directly. This means that
    /// the contract's calling context does not have access to storage (accessible via the proxy
    /// address).
    /// @param dexId the dex to execute the trade on
    /// @param trade trade object
    /// @param dynamicSlippageLimit the slippage limit in 1e8 precision
    /// @return amountSold amount of tokens sold
    /// @return amountBought amount of tokens purchased
    function executeTradeWithDynamicSlippage(
        uint16 dexId,
        Trade memory trade,
        uint32 dynamicSlippageLimit
    ) external override returns (uint256 amountSold, uint256 amountBought) {
        if (!PROXY.canExecuteTrade(address(this), dexId, trade)) revert InsufficientPermissions();
        if (trade.amount == 0) return (0, 0);

        // This method calls back into the implementation via the proxy so that it has proper
        // access to storage.
        trade.limit = PROXY.getLimitAmount(
            trade.tradeType,
            trade.sellToken,
            trade.buyToken,
            trade.amount,
            dynamicSlippageLimit
        );

        (
            address spender,
            address target,
            uint256 msgValue,
            bytes memory executionData
        ) = PROXY.getExecutionData(dexId, address(this), trade);

        return
            TradingUtils._executeInternal(
                trade,
                dexId,
                spender,
                target,
                msgValue,
                executionData
            );
    }

    /// @notice Should be called via delegate call to execute a trade on behalf of the caller.
    /// @param dexId enum representing the id of the dex
    /// @param trade trade object
    /// @return amountSold amount of tokens sold
    /// @return amountBought amount of tokens purchased
    function executeTrade(uint16 dexId, Trade calldata trade)
        external
        override
        returns (uint256 amountSold, uint256 amountBought)
    {
        if (!PROXY.canExecuteTrade(address(this), dexId, trade)) revert InsufficientPermissions();
        if (trade.amount == 0) return (0, 0);

        (
            address spender,
            address target,
            uint256 msgValue,
            bytes memory executionData
        ) = _getExecutionData(dexId, address(this), trade);

        return
            TradingUtils._executeInternal(
                trade,
                dexId,
                spender,
                target,
                msgValue,
                executionData
            );
    }

    function _getExecutionData(
        uint16 dexId,
        address from,
        Trade calldata trade
    )
        internal
        view
        returns (
            address spender,
            address target,
            uint256 msgValue,
            bytes memory executionCallData
        )
    {
        if (trade.buyToken == trade.sellToken) revert SellTokenEqualsBuyToken();

        if (DexId(dexId) == DexId.UNISWAP_V2) {
            return UniV2Adapter.getExecutionData(from, trade);
        } else if (DexId(dexId) == DexId.UNISWAP_V3) {
            return UniV3Adapter.getExecutionData(from, trade);
        } else if (DexId(dexId) == DexId.BALANCER_V2) {
            return BalancerV2Adapter.getExecutionData(from, trade);
        } else if (DexId(dexId) == DexId.CURVE) {
            return CurveAdapter.getExecutionData(from, trade);
        }

        revert UnknownDEX();
    }

    /// @notice Returns the Chainlink oracle price between the baseToken and the quoteToken, the
    /// Chainlink oracles. The quote currency between the oracles must match or the conversion
    /// in this method does not work. Most Chainlink oracles are baseToken/USD pairs.
    /// @param baseToken address of the first token in the pair, i.e. USDC in USDC/DAI
    /// @param quoteToken address of the second token in the pair, i.e. DAI in USDC/DAI
    /// @return answer exchange rate in rate decimals
    /// @return decimals number of decimals in the rate, currently hardcoded to 1e18
    function getOraclePrice(address baseToken, address quoteToken)
        public
        view
        override
        returns (int256 answer, int256 decimals)
    {
        PriceOracle memory baseOracle = priceOracles[baseToken];
        PriceOracle memory quoteOracle = priceOracles[quoteToken];

        int256 baseDecimals = int256(10**baseOracle.rateDecimals);
        int256 quoteDecimals = int256(10**quoteOracle.rateDecimals);

        (/* */, int256 basePrice, /* */, uint256 bpUpdatedAt, /* */) = baseOracle.oracle.latestRoundData();
        require(block.timestamp - bpUpdatedAt <= maxOracleFreshnessInSeconds);
        require(basePrice > 0); /// @dev: Chainlink Rate Error

        (/* */, int256 quotePrice, /* */, uint256 qpUpdatedAt, /* */) = quoteOracle.oracle.latestRoundData();
        require(block.timestamp - qpUpdatedAt <= maxOracleFreshnessInSeconds);
        require(quotePrice > 0); /// @dev: Chainlink Rate Error

        answer =
            (basePrice * quoteDecimals * RATE_DECIMALS) /
            (quotePrice * baseDecimals);
        decimals = RATE_DECIMALS;
    }

    function _hasPermission(uint32 flags, uint32 flagID) private pure returns (bool) {
        return (flags & flagID) == flagID;
    }

    /// @notice Check if the caller is allowed to execute the provided trade object
    function canExecuteTrade(address from, uint16 dexId, Trade calldata trade) external view override returns (bool) {
        TokenPermissions memory permissions = tokenWhitelist[from][trade.sellToken];
        if (!_hasPermission(permissions.dexFlags, uint32(1 << dexId))) {
            return false;
        }
        if (!_hasPermission(permissions.tradeTypeFlags, uint32(1 << uint32(trade.tradeType)))) {
            return false;
        }
        return permissions.allowSell;
    }

    function getLimitAmount(
        TradeType tradeType,
        address sellToken,
        address buyToken,
        uint256 amount,
        uint32 slippageLimit
    ) external view override returns (uint256 limitAmount) {
        // prettier-ignore
        (int256 oraclePrice, int256 oracleDecimals) = getOraclePrice(sellToken, buyToken);

        require(oraclePrice >= 0); /// @dev Chainlink rate error
        require(oracleDecimals >= 0); /// @dev Chainlink decimals error

        limitAmount = TradingUtils._getLimitAmount({
            tradeType: tradeType,
            sellToken: sellToken,
            buyToken: buyToken,
            amount: amount,
            slippageLimit: slippageLimit,
            oraclePrice: uint256(oraclePrice),
            oracleDecimals: uint256(oracleDecimals)
        });
    }
}