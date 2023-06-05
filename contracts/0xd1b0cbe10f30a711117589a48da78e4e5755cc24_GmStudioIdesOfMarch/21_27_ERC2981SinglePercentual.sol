// SPDX-License-Identifier: MIT
// Copyright 2021 David Huber (@cxkoda)

pragma solidity >=0.8.0 <0.9.0;

import "./ERC2981.sol";

/**
 * @notice ERC2981 royalty info implementation for a single beneficiary
 * receving a percentage of sales prices.
 * @author David Huber (@cxkoda)
 */
contract ERC2981SinglePercentual is ERC2981 {
    /**
     * @dev The royalty percentage (in units of 0.01%)
     */
    uint96 private _percentage;

    /**
     * @dev The address to receive the royalties
     */
    address private _receiver;

    /**
     * @dev See {IERC2981-royaltyInfo}.
     */
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        royaltyAmount = (salePrice / 10000) * _percentage;
        receiver = _receiver;
    }

    /**
     * @dev Sets the royalty percentage (in units of 0.01%)
     */
    function _setRoyaltyPercentage(uint96 percentage_) internal {
        _percentage = percentage_;
    }

    /**
     * @dev Sets the address to receive the royalties
     */
    function _setRoyaltyReceiver(address receiver_) internal {
        _receiver = receiver_;
    }
}