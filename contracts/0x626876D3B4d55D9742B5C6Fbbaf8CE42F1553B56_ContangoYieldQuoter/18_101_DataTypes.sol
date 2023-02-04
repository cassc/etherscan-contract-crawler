//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IFeeModel.sol";
import "solmate/src/tokens/ERC20.sol";
import {IFYToken} from "@yield-protocol/vault-v2/contracts/interfaces/IFYToken.sol";
import {IPool} from "@yield-protocol/yieldspace-tv/src/interfaces/IPool.sol";

type Symbol is bytes32;

type PositionId is uint256;

struct Position {
    Symbol symbol;
    uint256 openQuantity; // total quantity to which the trader is exposed
    uint256 openCost; // total amount that the trader exchanged for base
    int256 collateral; // Trader collateral
    uint256 protocolFees; // Fees this position accrued
    uint32 maturity; // Position maturity
    IFeeModel feeModel; // Fee model for this position
}

// Represents an execution of a trade, kinda similar to an execution report in FIX
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
    // This value used to be stored, but now is passed as param. It can't be removed cause of the existent data in the contract
    // So to also avoid a major refactor is used as a transient value, i.e. it's set after the struct is loaded using the user provided value
    uint24 uniswapFeeTransient;
    ERC20 base;
    bool closingOnly;
    //>slot1: 160bits used - 96bits left
    ERC20 quote;
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