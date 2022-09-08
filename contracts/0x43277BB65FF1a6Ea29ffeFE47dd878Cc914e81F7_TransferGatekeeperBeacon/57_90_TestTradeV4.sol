// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../market/EnigmaMarket.sol";

/// @title TestTradeV4
///
/// @dev This contract extends from Trade Series for upgradeablity testing

contract TestTradeV4 is TradeV4 {
    function initialize(
        uint8 _buyerFee,
        uint8 _sellerFee,
        ITransferProxy _transferProxy,
        address _enigmaNFT721Address,
        address _enigmaNFT1155Address,
        address _custodialAddress
    ) external initializer {
        initializeTradeV4(
            _buyerFee,
            _sellerFee,
            _transferProxy,
            _enigmaNFT721Address,
            _enigmaNFT1155Address,
            _custodialAddress
        );
    }
}