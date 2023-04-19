// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../../../ext-contracts/@openzeppelin/contracts/token/common/ERC2981.sol";
import "./CashCollector.sol";

abstract contract RoyaltyReceiver is CashCollector, ERC2981 {
    constructor(
        address accountOwner,
        uint96 numerator,
        IERC20[] memory paymentTokens
    ) CashCollector(accountOwner, paymentTokens) {
        _setDefaultRoyalty(address(this), numerator);
    }

    function feeDenominator() public pure returns (uint96) {
        return _feeDenominator();
    }
}