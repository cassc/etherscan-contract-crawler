// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2022 Simplr
pragma solidity 0.8.11;

import "./RoyaltiesA.sol";
import "../../../affiliate/Affiliate.sol";

/// @title AffiliableA
/// @author Chain Labs
/// @notice Module that adds functionality of affiliate.
/// @dev Uses Simplr Affiliate Infrastructure
contract AffiliableA is RoyaltiesA, Affiliate {
    //------------------------------------------------------//
    //
    //  Modifiers
    //
    //------------------------------------------------------//

    modifier affiliatePurchase(bytes memory _signature, address _affiliate) {
        _;
        _transferAffiliateShare(_signature, _affiliate, msg.value);
    }

    //------------------------------------------------------//
    //
    //  Public function
    //
    //------------------------------------------------------//

    /// @notice Buy using Affiliate shares
    /// @dev Transfers the affiliate share directly to affiliate address
    /// @param _receiver address of buyer
    /// @param _quantity number of tokens to be bought
    /// @param _signature unique signature of affiliate
    /// @param _affiliate address of affiliate
    function affiliateBuy(
        address _receiver,
        uint256 _quantity,
        bytes memory _signature,
        address _affiliate
    ) external payable virtual affiliatePurchase(_signature, _affiliate) {
        _buy(_receiver, _quantity);
    }

    /// @notice presale buy using Affiliate shares
    /// @dev Transfers the affiliate share directly to affiliate address
    /// @param _proofs merkle proof for whitelist
    /// @param _receiver address of buyer
    /// @param _quantity number of tokens to be bought
    /// @param _signature unique signature of affiliate
    /// @param _affiliate address of affiliate
    function affiliatePresaleBuy(
        bytes32[] calldata _proofs,
        address _receiver,
        uint256 _quantity,
        bytes memory _signature,
        address _affiliate
    ) external payable virtual affiliatePurchase(_signature, _affiliate) {
        _presaleBuy(_proofs, _receiver, _quantity);
    }

    /// @notice is affiliate module active or not
    /// @dev once set, it cannot be updated
    /// @return boolean checks if affiliate module is active or not
    function isAffiliateModuleInitialised() external view returns (bool) {
        return _isAffiliateModuleInitialised();
    }
}