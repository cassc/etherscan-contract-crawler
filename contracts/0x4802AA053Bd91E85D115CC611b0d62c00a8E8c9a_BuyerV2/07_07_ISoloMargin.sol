// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;
pragma experimental ABIEncoderV2;

library Account {
    enum Status {
        Normal,
        Liquid,
        Vapor
    }
    struct Info {
        address owner; // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }
    struct accStorage {
        mapping(uint256 => Types.Par) balances; // Mapping from marketId to principal
        Status status;
    }
}

library Actions {
    enum ActionType {
        Deposit, // supply tokens
        Withdraw, // borrow tokens
        Transfer, // transfer balance between accounts
        Buy, // buy an amount of some token (publicly)
        Sell, // sell an amount of some token (publicly)
        Trade, // trade tokens against another account
        Liquidate, // liquidate an undercollateralized or expiring account
        Vaporize, // use excess tokens to zero-out a completely negative account
        Call // send arbitrary data to an address
    }

    enum AccountLayout {
        OnePrimary,
        TwoPrimary,
        PrimaryAndSecondary
    }

    enum MarketLayout {
        ZeroMarkets,
        OneMarket,
        TwoMarkets
    }

    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        Types.AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    struct DepositArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 market;
        address from;
    }

    struct WithdrawArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 market;
        address to;
    }

    struct TransferArgs {
        Types.AssetAmount amount;
        Account.Info accountOne;
        Account.Info accountTwo;
        uint256 market;
    }

    struct BuyArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 makerMarket;
        uint256 takerMarket;
        address exchangeWrapper;
        bytes orderData;
    }

    struct SellArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 takerMarket;
        uint256 makerMarket;
        address exchangeWrapper;
        bytes orderData;
    }

    struct TradeArgs {
        Types.AssetAmount amount;
        Account.Info takerAccount;
        Account.Info makerAccount;
        uint256 inputMarket;
        uint256 outputMarket;
        address autoTrader;
        bytes tradeData;
    }

    struct LiquidateArgs {
        Types.AssetAmount amount;
        Account.Info solidAccount;
        Account.Info liquidAccount;
        uint256 owedMarket;
        uint256 heldMarket;
    }

    struct VaporizeArgs {
        Types.AssetAmount amount;
        Account.Info solidAccount;
        Account.Info vaporAccount;
        uint256 owedMarket;
        uint256 heldMarket;
    }

    struct CallArgs {
        Account.Info account;
        address callee;
        bytes data;
    }
}

library Decimal {
    struct D256 {
        uint256 value;
    }
}

library Interest {
    struct Rate {
        uint256 value;
    }

    struct Index {
        uint96 borrow;
        uint96 supply;
        uint32 lastUpdate;
    }
}

library Monetary {
    struct Price {
        uint256 value;
    }
    struct Value {
        uint256 value;
    }
}

library Storage {
    // All information necessary for tracking a market
    struct Market {
        // Contract address of the associated ERC20 token
        address token;
        // Total aggregated supply and borrow amount of the entire market
        Types.TotalPar totalPar;
        // Interest index of the market
        Interest.Index index;
        // Contract address of the price oracle for this market
        address priceOracle;
        // Contract address of the interest setter for this market
        address interestSetter;
        // Multiplier on the marginRatio for this market
        Decimal.D256 marginPremium;
        // Multiplier on the liquidationSpread for this market
        Decimal.D256 spreadPremium;
        // Whether additional borrows are allowed for this market
        bool isClosing;
    }

    // The global risk parameters that govern the health and security of the system
    struct RiskParams {
        // Required ratio of over-collateralization
        Decimal.D256 marginRatio;
        // Percentage penalty incurred by liquidated accounts
        Decimal.D256 liquidationSpread;
        // Percentage of the borrower's interest fee that gets passed to the suppliers
        Decimal.D256 earningsRate;
        // The minimum absolute borrow value of an account
        // There must be sufficient incentivize to liquidate undercollateralized accounts
        Monetary.Value minBorrowedValue;
    }

    // The maximum RiskParam values that can be set
    struct RiskLimits {
        uint64 marginRatioMax;
        uint64 liquidationSpreadMax;
        uint64 earningsRateMax;
        uint64 marginPremiumMax;
        uint64 spreadPremiumMax;
        uint128 minBorrowedValueMax;
    }

    // The entire storage state of Solo
    struct State {
        // number of markets
        uint256 numMarkets;
        // marketId => Market
        mapping(uint256 => Market) markets;
        // owner => account number => Account
        mapping(address => mapping(uint256 => Account.accStorage)) accounts;
        // Addresses that can control other users accounts
        mapping(address => mapping(address => bool)) operators;
        // Addresses that can control all users accounts
        mapping(address => bool) globalOperators;
        // mutable risk parameters of the system
        RiskParams riskParams;
        // immutable risk limits of the system
        RiskLimits riskLimits;
    }
}

library Types {
    enum AssetDenomination {
        Wei, // the amount is denominated in wei
        Par // the amount is denominated in par
    }

    enum AssetReference {
        Delta, // the amount is given as a delta from the current value
        Target // the amount is given as an exact number to end up at
    }

    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    struct TotalPar {
        uint128 borrow;
        uint128 supply;
    }

    struct Par {
        bool sign; // true if positive
        uint128 value;
    }

    struct Wei {
        bool sign; // true if positive
        uint256 value;
    }
}

interface ISoloMargin {
    struct OperatorArg {
        address operator;
        bool trusted;
    }

    function ownerSetSpreadPremium(
        uint256 marketId,
        Decimal.D256 calldata spreadPremium
    ) external;

    function getIsGlobalOperator(address operator) external view returns (bool);

    function getMarketTokenAddress(uint256 marketId)
        external
        view
        returns (address);

    function ownerSetInterestSetter(uint256 marketId, address interestSetter)
        external;

    function getAccountValues(Account.Info calldata account)
        external
        view
        returns (Monetary.Value memory, Monetary.Value memory);

    function getMarketPriceOracle(uint256 marketId)
        external
        view
        returns (address);

    function getMarketInterestSetter(uint256 marketId)
        external
        view
        returns (address);

    function getMarketSpreadPremium(uint256 marketId)
        external
        view
        returns (Decimal.D256 memory);

    function getNumMarkets() external view returns (uint256);

    function ownerWithdrawUnsupportedTokens(address token, address recipient)
        external
        returns (uint256);

    function ownerSetMinBorrowedValue(Monetary.Value calldata minBorrowedValue)
        external;

    function ownerSetLiquidationSpread(Decimal.D256 calldata spread) external;

    function ownerSetEarningsRate(Decimal.D256 calldata earningsRate) external;

    function getIsLocalOperator(address _owner, address operator)
        external
        view
        returns (bool);

    function getAccountPar(Account.Info calldata account, uint256 marketId)
        external
        view
        returns (Types.Par memory);

    function ownerSetMarginPremium(
        uint256 marketId,
        Decimal.D256 calldata marginPremium
    ) external;

    function getMarginRatio() external view returns (Decimal.D256 memory);

    function getMarketCurrentIndex(uint256 marketId)
        external
        view
        returns (Interest.Index memory);

    function getMarketIsClosing(uint256 marketId) external view returns (bool);

    function getRiskParams() external view returns (Storage.RiskParams memory);

    function getAccountBalances(Account.Info calldata account)
        external
        view
        returns (
            address[] memory,
            Types.Par[] memory,
            Types.Wei[] memory
        );

    function renounceOwnership() external;

    function getMinBorrowedValue()
        external
        view
        returns (Monetary.Value memory);

    function setOperators(OperatorArg[] calldata args) external;

    function getMarketPrice(uint256 marketId) external view returns (address);

    function owner() external view returns (address);

    function isOwner() external view returns (bool);

    function ownerWithdrawExcessTokens(uint256 marketId, address recipient)
        external
        returns (uint256);

    function ownerAddMarket(
        address token,
        address priceOracle,
        address interestSetter,
        Decimal.D256 calldata marginPremium,
        Decimal.D256 calldata spreadPremium
    ) external;

    function operate(
        Account.Info[] calldata accounts,
        Actions.ActionArgs[] calldata actions
    ) external;

    function getMarketWithInfo(uint256 marketId)
        external
        view
        returns (
            Storage.Market memory,
            Interest.Index memory,
            Monetary.Price memory,
            Interest.Rate memory
        );

    function ownerSetMarginRatio(Decimal.D256 calldata ratio) external;

    function getLiquidationSpread() external view returns (Decimal.D256 memory);

    function getAccountWei(Account.Info calldata account, uint256 marketId)
        external
        view
        returns (Types.Wei memory);

    function getMarketTotalPar(uint256 marketId)
        external
        view
        returns (Types.TotalPar memory);

    function getLiquidationSpreadForPair(
        uint256 heldMarketId,
        uint256 owedMarketId
    ) external view returns (Decimal.D256 memory);

    function getNumExcessTokens(uint256 marketId)
        external
        view
        returns (Types.Wei memory);

    function getMarketCachedIndex(uint256 marketId)
        external
        view
        returns (Interest.Index memory);

    function getAccountStatus(Account.Info calldata account)
        external
        view
        returns (uint8);

    function getEarningsRate() external view returns (Decimal.D256 memory);

    function ownerSetPriceOracle(uint256 marketId, address priceOracle)
        external;

    function getRiskLimits() external view returns (Storage.RiskLimits memory);

    function getMarket(uint256 marketId)
        external
        view
        returns (Storage.Market memory);

    function ownerSetIsClosing(uint256 marketId, bool isClosing) external;

    function ownerSetGlobalOperator(address operator, bool approved) external;

    function transferOwnership(address newOwner) external;

    function getAdjustedAccountValues(Account.Info calldata account)
        external
        view
        returns (Monetary.Value memory, Monetary.Value memory);

    function getMarketMarginPremium(uint256 marketId)
        external
        view
        returns (Decimal.D256 memory);

    function getMarketInterestRate(uint256 marketId)
        external
        view
        returns (Interest.Rate memory);
}