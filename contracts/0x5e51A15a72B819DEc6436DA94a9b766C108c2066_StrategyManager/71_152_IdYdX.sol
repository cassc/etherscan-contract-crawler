// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.9.0;
pragma experimental ABIEncoderV2;

enum ActionType {
    Deposit, // supply tokens
    Withdraw, // borrow tokens
    Transfer, // transfer balance between accounts
    Buy, // buy an amount of some token (externally)
    Sell, // sell an amount of some token (externally)
    Trade, // trade tokens against another account
    Liquidate, // liquidate an undercollateralized or expiring account
    Vaporize, // use excess tokens to zero-out a completely negative account
    Call // send arbitrary data to an address
}

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

struct AccountInfo {
    address owner;
    uint256 number;
}

struct ActionArgs {
    ActionType actionType;
    uint256 accountId;
    AssetAmount amount;
    uint256 primaryMarketId;
    uint256 secondaryMarketId;
    address otherAddress;
    uint256 otherAccountId;
    bytes data;
}

struct OperatorArg {
    address operator;
    bool trusted;
}

struct TotalPar {
    uint128 borrow;
    uint128 supply;
}

interface IdYdX {
    function operate(AccountInfo[] memory _accountInfo, ActionArgs[] memory _actionArgs) external;

    function setOperators(OperatorArg[] memory args) external;

    function getAccountWei(AccountInfo calldata _accountInfo, uint256 marketId) external view returns (bool, uint256);

    function getMarketTotalPar(uint256 marketId) external view returns (TotalPar memory);
}