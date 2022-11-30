//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../dependencies/Uniswap.sol";
import "../interfaces/IFeeModel.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IFYToken} from "@yield-protocol/vault-v2/contracts/interfaces/IFYToken.sol";
import {IPool} from "@yield-protocol/yieldspace-tv/src/interfaces/IPool.sol";

type Symbol is bytes32;

type PositionId is uint256;

struct OpeningCostParams {
    Symbol symbol; // Instrument to be used
    uint256 quantity; // Size of the position
    uint256 collateral; // How much quote ccy the user will post, if the value is too big/small, a calculated max/min will be used instead
    uint256 collateralSlippage; // How much add to minCollateral and remove from maxCollateral to avoid issues with min/max debt. In %, 1e18 == 100%
}

struct ModifyCostParams {
    PositionId positionId;
    int256 quantity; // How much the size of the position should change by
    int256 collateral; // How much the collateral of the position should change by, if the value is too big/small, a calculated max/min will be used instead
    uint256 collateralSlippage; // How much add to minCollateral and remove from maxCollateral to avoid issues with min/max debt. In %, 1e18 == 100%
}

// What does the signed cost mean?
// In general, it'll be negative when quoting cost to open/increase, and positive when quoting cost to close/decrease.
// However, there are certain situations where that general rule may not hold true, for example when the qty delta is small and the collateral delta is big.
// Scenarios include:
//      * increase position by a tiny bit, but add a lot of collateral at the same time (aka. burn existing debt)
//      * decrease position by a tiny bit, withdraw a lot of excess equity at the same time (aka. issue new debt)
// For this reason, we cannot get rid of the signing, and make assumptions about in which direction the cost will go based on the qty delta alone.
// The effect (or likeliness of this coming into play) is much greater when the funding currency (quote) has a high interest rate.
struct ModifyCostResult {
    int256 spotCost; // The current spot cost of a given position quantity
    int256 cost; // See comment above for explanation of why the cost is signed.
    int256 financingCost; // The cost to increase/decrease collateral. We need to return this breakdown of cost so the UI knows which values to pass to 'modifyCollateral'
    int256 debtDelta; // if negative, it's the amount repaid. If positive, it's the amount of new debt issued.
    int256 collateralUsed; // Collateral used to open/increase position with returned cost
    int256 minCollateral; // Minimum collateral needed to perform modification. If negative, it's the MAXIMUM amount that CAN be withdrawn.
    int256 maxCollateral; // Max collateral allowed to open/increase a position. If negative, it's the MINIMUM amount that HAS TO be withdrawn.
    uint256 underlyingDebt; // Value of debt 1:1 with real underlying (Future Value)
    uint256 underlyingCollateral; // Value of collateral in debt terms
    uint256 liquidationRatio; // The ratio at which a position becomes eligible for liquidation (underlyingCollateral/underlyingDebt)
    uint256 fee;
    uint128 minDebt;
    uint256 baseLendingLiquidity; // Liquidity available for lending, either in PV or FV depending on the operation(s) quoted
    uint256 quoteLendingLiquidity; // Liquidity available for lending, either in PV or FV depending on the operation(s) quoted
    // relevant to closing only
    bool insufficientLiquidity; // Indicates whether there is insufficient liquidity for the desired modification/open.
    // when opening/increasing, this would mean there is insufficient borrowing liquidity of quote ccy.
    // when closing/decreasing, this would mean there is insufficient borrowing liquidity of base ccy (unwind hedge).
    // If this boolean is true, there is nothing we can do.
    bool needsBatchedCall;
}

struct PositionStatus {
    uint256 spotCost; // The current spot cost of a given position quantity
    uint256 underlyingDebt; // Value of debt 1:1 with real underlying (Future Value)
    uint256 underlyingCollateral; // Value of collateral in debt terms
    uint256 liquidationRatio; // The ratio at which a position becomes eligible for liquidation (underlyingCollateral/underlyingDebt)
    bool liquidating; // When true, no actions are allowed over the position
}

struct Position {
    Symbol symbol;
    uint256 openQuantity; // total quantity to which the trader is exposed
    uint256 openCost; // total amount that the trader exchanged for base
    int256 collateral; // User collateral
    uint256 protocolFees; // fees this position owes
    uint32 maturity;
    IFeeModel feeModel;
}

// Represents an execution of a futures trade, kinda similar to an execution report in traditional finance
struct Fill {
    uint256 size; // Size of the fill (base ccy)
    uint256 cost; // Amount of quote traded in exchange for the base
    uint256 hedgeSize; // Actual amount of base ccy traded on the spot market
    uint256 hedgeCost; // Actual amount of quote ccy traded on the spot market
    int256 collateral; // Amount of collateral added/removed by this fill
}

struct Instrument {
    //>slot0: 216bits used - 40bits left
    uint32 maturity;
    uint24 uniswapFee;
    IERC20Metadata base;
    //>slot1: 160bits used - 96bits left
    IERC20Metadata quote;
}

struct YieldInstrument {
    //>slot0: 256bits used
    bytes6 baseId;
    bytes6 quoteId;
    IFYToken quoteFyToken;
    //>slot1: 160bits used - 96bits left
    IFYToken baseFyToken;
    //>slot2: 160bits used - 96bits left
    IPool basePool;
    //>slot3: 256bits used
    IPool quotePool;
    uint96 minQuoteDebt;
}

struct NotionalInstrument {
    //>slot0: 161bits used - 95bits left
    uint16 baseId;
    uint16 quoteId;
    uint64 basePrecision;
    uint64 quotePrecision;
    bool isQuoteWeth;
}