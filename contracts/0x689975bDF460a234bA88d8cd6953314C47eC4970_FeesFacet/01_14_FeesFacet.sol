// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import {IFeesFacet} from "../interfaces/IFeesFacet.sol";
import {Modifiers} from "../libs/LibAppStorage.sol";

/// @title meTokens Fees Facet
/// @author @cartercarlson, @parv3213
/// @notice This contract defines the fee structure for meTokens Protocol
contract FeesFacet is IFeesFacet, Modifiers {
    /// @inheritdoc IFeesFacet
    function setMintFee(uint256 rate) external override onlyFeesController {
        require(rate != s.mintFee && rate < s.MAX_FEE, "out of range");
        s.mintFee = rate;
        emit SetMintFee(rate);
    }

    /// @inheritdoc IFeesFacet
    function setBurnBuyerFee(uint256 rate)
        external
        override
        onlyFeesController
    {
        require(rate != s.burnBuyerFee && rate < s.MAX_FEE, "out of range");
        s.burnBuyerFee = rate;
        emit SetBurnBuyerFee(rate);
    }

    /// @inheritdoc IFeesFacet
    function setBurnOwnerFee(uint256 rate)
        external
        override
        onlyFeesController
    {
        require(rate != s.burnOwnerFee && rate < s.MAX_FEE, "out of range");
        s.burnOwnerFee = rate;
        emit SetBurnOwnerFee(rate);
    }

    /// @inheritdoc IFeesFacet
    function mintFee() external view override returns (uint256) {
        return s.mintFee;
    }

    /// @inheritdoc IFeesFacet
    function burnBuyerFee() external view override returns (uint256) {
        return s.burnBuyerFee;
    }

    /// @inheritdoc IFeesFacet
    function burnOwnerFee() external view override returns (uint256) {
        return s.burnOwnerFee;
    }
}