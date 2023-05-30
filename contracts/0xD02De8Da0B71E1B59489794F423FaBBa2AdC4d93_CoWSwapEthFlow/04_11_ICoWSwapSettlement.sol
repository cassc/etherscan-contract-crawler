// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8;

/// @title CoW Swap Settlement Contract Interface
/// @author CoW Swap Developers
/// @dev This interface collects the functions of the CoW Swap settlement contract that are used by the ETH flow
/// contract.
interface ICoWSwapSettlement {
    /// @dev Map each user order by UID to the amount that has been filled so
    /// far. If this amount is larger than or equal to the amount traded in the
    /// order (amount sold for sell orders, amount bought for buy orders) then
    /// the order cannot be traded anymore. If the order is fill or kill, then
    /// this value is only used to determine whether the order has already been
    /// executed.
    /// @param orderUid The uinique identifier to use to retrieve the filled amount.
    function filledAmount(bytes memory orderUid) external returns (uint256);

    /// @dev The address of the vault relayer: the contract that handles withdrawing tokens from the user to the
    /// settlement contract. A user who wants to sell a token on CoW Swap must approve this contract to spend the token.
    function vaultRelayer() external returns (address);
}