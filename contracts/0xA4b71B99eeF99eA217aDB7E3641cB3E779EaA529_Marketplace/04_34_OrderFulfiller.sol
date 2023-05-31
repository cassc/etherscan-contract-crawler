// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./transfer/TransferHelper.sol";
import "./fees/FeeProvider.sol";
import {Asset} from "./Structs.sol";

contract OrderFulfiller is FeeProvider, TransferHelper {
    /**
     * @dev perform a transfer of all provided assets between `from` and `to` addresses
     *
     * @param payment  assets to transfer
     * @param from     assets sender
     * @param to       assets receiver
     */
    function fulfillOrderPart(
        Asset[] calldata payment,
        uint256 amount,
        address from,
        address to
    ) internal {
        for (uint256 i = 0; i < payment.length; ) {
            _transfer(
                from,
                to,
                payment[i].assetType,
                payment[i].collection,
                payment[i].id,
                payment[i].amount * amount
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev perform `transferPaymentAndFees` in batch
     *
     * @param payment  assets to transfer
     * @param assets   assets to calculate order fee
     * @param from     assets sender
     * @param to       assets receiver
     */
    function fulfillOrderPartWithFee(
        Asset[] calldata payment,
        Asset[] calldata assets,
        uint256 amount,
        address from,
        address to
    ) internal {
        for (uint256 i = 0; i < payment.length; ) {
            transferPaymentAndFees(
                from,
                to,
                payment[i],
                assets[0],
                assets.length == 1,
                amount
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev calculates and transfers fees to royalty recipients and marketplace beneficiary
     *
     * @param from              address from which fees and payment is taken
     * @param to                address who receives payment
     * @param payment           assets to transfer
     * @param asset             assets to calculate order fee
     * @param royaltiesApplied  collection which is used to take fees
     */
    function transferPaymentAndFees(
        address from,
        address to,
        Asset calldata payment,
        Asset calldata asset,
        bool royaltiesApplied,
        uint256 amount
    ) internal {
        uint256 fee;
        // 1. marketplace fees
        {
            MarketplaceFee memory marketplaceFee = _getMarketplaceFee(
                asset.collection
            );
            uint256 buyerFee = calculateFee(
                payment.amount,
                marketplaceFee.buyerFee
            );
            uint256 sellerFee = calculateFee(
                payment.amount,
                marketplaceFee.sellerFee
            );

            fee = (buyerFee + sellerFee) * amount;

            if (fee > 0) {
                _transfer(
                    from,
                    _getFeesBeneficiary(),
                    payment.assetType,
                    payment.collection,
                    payment.id,
                    fee
                );
            }
        }

        // 2. royalties
        if (royaltiesApplied) {
            (
                address payable[] memory recipients,
                uint16[] memory fees
            ) = _getRoyalties(asset.collection, asset.id);

            for (uint256 i = 0; i < recipients.length; ) {
                uint256 royalty = calculateFee(payment.amount, fees[i]) * amount;
                fee += royalty;

                _transfer(
                    from,
                    recipients[i],
                    payment.assetType,
                    payment.collection,
                    payment.id,
                    royalty
                );
                unchecked {
                    ++i;
                }
            }
        }

        // 3. payment
        _transfer(
            from,
            to,
            payment.assetType,
            payment.collection,
            payment.id,
            payment.amount * amount - fee
        );
    }
}