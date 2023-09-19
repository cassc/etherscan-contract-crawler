// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2022 Simplr
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";
import "../base/BaseCollectionA.sol";

/// @title Payment SplitableA
/// @author Chain Labs
/// @notice Module that adds functionality of payment splitting
/// @dev Core functionality inherited from OpenZeppelin's Payment Splitter
contract PaymentSplitableA is BaseCollectionA, PaymentSplitterUpgradeable {
    //------------------------------------------------------//
    //
    //  Storage
    //
    //------------------------------------------------------//
    /// @notice Shares of Simplr in the sale
    /// @dev percentage (eg. 100% - 10^18) of simplr in the sale
    /// @return SIMPLR_SHARES shares of simplr currently set to 0.0000000000000001%
    uint256 public SIMPLR_SHARES; // share of Simplr

    /// @notice address of Simplr's Fee receiver
    /// @dev Gnosis Safe Simplr Fee Receiver
    /// @return SIMPLR_RECEIVER_ADDRESS address that will receive fee i.e. Simplr Shares
    address public SIMPLR_RECEIVER_ADDRESS; // address of SIMPLR to receive shares

    //------------------------------------------------------//
    //
    //  Setup
    //
    //------------------------------------------------------//

    /// @notice setup payment splitting details for collection
    /// @dev internal method and only be invoked once during setup
    /// @param _simplr address of simplr beneficicary address
    /// @param _simplrShares percentage share of simplr, eg. 15% = parseUnits(15,16) or toWei(0.15) or 15*10^16
    /// @param _payees array of payee address
    /// @param _shares array of payee shares, index for both arrays should match for a payee
    function setupPaymentSplitter(
        address _simplr,
        uint256 _simplrShares,
        address[] memory _payees,
        uint256[] memory _shares
    ) internal {
        require(_payees.length == _shares.length, "PS:001");
        SIMPLR_RECEIVER_ADDRESS = _simplr;
        SIMPLR_SHARES = _simplrShares;
        _payees[_payees.length - 1] = _simplr;
        _shares[_payees.length - 1] = _simplrShares;
        __PaymentSplitter_init(_payees, _shares);
    }
}