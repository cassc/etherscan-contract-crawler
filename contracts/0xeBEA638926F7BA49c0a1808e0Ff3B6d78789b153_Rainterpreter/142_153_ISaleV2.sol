// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

/// An `ISaleV2` can be in one of 4 possible states and a linear progression is
/// expected from an "in flight" status to an immutable definitive outcome.
/// - Pending: The sale is deployed onchain but cannot be interacted with yet.
/// - Active: The sale can now be bought into and otherwise interacted with.
/// - Success: The sale has ended AND reached its minimum raise target.
/// - Fail: The sale has ended BUT NOT reached its minimum raise target.
/// Once an `ISaleV2` reaches `Active` it MUST NOT return `Pending` ever again.
/// Once an `ISaleV2` reaches `Success` or `Fail` it MUST NOT return any other
/// status ever again.
enum SaleStatus {
    Pending,
    Active,
    Success,
    Fail
}

interface ISaleV2 {
    /// Returns the address of the token being sold in the sale.
    /// MUST NOT change during the lifecycle of the sale contract.
    function token() external view returns (address);

    function remainingTokenInventory() external view returns (uint256);

    /// Returns the address of the token that sale prices are denominated in.
    /// MUST NOT change during the lifecycle of the sale contract.
    function reserve() external view returns (address);

    /// total reserve taken in to the sale contract via. buys. Does NOT
    /// include any reserve sent directly to the sale contract outside the
    /// standard buy/refund loop, e.g. due to a dusting attack.
    function totalReserveReceived() external view returns (uint256);

    /// Returns the current `SaleStatus` of the sale.
    /// Represents a linear progression of the sale through its major lifecycle
    /// events.
    function saleStatus() external view returns (SaleStatus);
}