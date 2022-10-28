// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

struct TokenBatchPrice {
    uint128 pricePaid;
    uint8 quantityMinted;
}

library DAHelper {
    function _getRefund(
        address user,
        mapping(address => TokenBatchPrice[]) storage _userToTokenBatchPrices,
        uint256 _DISCOUNT_PERCENT,
        uint256 _DA_FINAL_PRICE
    ) internal returns (uint256) {
        TokenBatchPrice[] storage tokenBatchPrices = _userToTokenBatchPrices[user];
        uint256 totalRefund;
        for (
            uint256 i = tokenBatchPrices.length;
            i > 0;
            i--
        ) {
            //This is what they should have paid if they bought at lowest price tier.
            uint256 expectedPrice = tokenBatchPrices[i - 1]
                .quantityMinted * _DA_FINAL_PRICE * (100 - _DISCOUNT_PERCENT) / 100;

            //What they paid - what they should have paid = refund.
            uint256 refund = tokenBatchPrices[i - 1]
                .pricePaid - expectedPrice;

            //Remove this tokenBatch
            tokenBatchPrices.pop();

            //Send them their extra monies.
            totalRefund += refund;
        }
        return totalRefund;
    }
}