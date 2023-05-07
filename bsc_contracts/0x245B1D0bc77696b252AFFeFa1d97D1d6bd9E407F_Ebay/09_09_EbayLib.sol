// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library EbayLib {
    using SafeMath for uint256;
        enum Status {
        Initial, //待购买0
        Ordered, //被下单1
        Completed, //已完成2
        BuyerBreak, //买家毁约3
        SellerBreak, //卖家毁约4
        SellerCancelWithoutDuty, //卖家无责取消5
        BuyerLanchCancel, //买家发起取消6
        SellerLanchCancel, //卖家发起取消7
        SellerRejectCancel, //卖家拒绝取消8
        BuyerRejectCancel, //买家拒绝取消9
        ConsultCancelCompleted //协商取消完成10
    }
    function calculateSellerPledge(
        uint256 price,
        uint256 amount,
        uint256 sellerRatio,
        uint256 sellerRate
    ) internal pure returns (uint256 sellerPledge, uint256 sellerTxFee) {
        sellerPledge = price.mul(amount).mul(sellerRatio).div(10000);
        sellerTxFee = price.mul(amount).mul(sellerRate).div(10000);
        if (sellerPledge < sellerTxFee) {
            sellerPledge = sellerTxFee;
        }
        return (sellerPledge, sellerTxFee);
    }

    function calculateBuyerTxFeeAndExcess(
        uint256 price,
        uint256 amount,
        uint256 buyerRate,
        uint256 buyerIncRatio
    ) internal pure returns (uint256 buyerTxFee, uint256 buyerExcess) {
        buyerTxFee = price.mul(amount).mul(buyerRate).div(10000);
        buyerExcess = price.mul(amount).mul(buyerIncRatio).div(10000);
        if (buyerTxFee > buyerExcess) {
            buyerExcess = buyerTxFee;
        }
        return (buyerTxFee, buyerExcess);
    }

    function confirmCalculateRefunds(
        uint256 sellerPledge,
        uint256 buyerPledge,
        uint256 price,
        uint256 amount,
        uint256 buyerRate,
        uint256 sellerRate,
        uint256 buyerEx
    )
        internal
        pure
        returns (
            uint256 sellerFee,
            uint256 buyerFee,
            uint256 sellerBack,
            uint256 buyerBack
        )
    {
        sellerFee = price.mul(amount).mul(sellerRate).div(10000);
        if (sellerPledge < sellerFee) {
            sellerFee = sellerPledge;
        }
        buyerFee = price.mul(amount).mul(buyerRate).div(10000);
        if (buyerEx < buyerFee) {
            buyerFee = buyerEx;
        }
        sellerBack = (sellerPledge + (price.mul(amount))).sub(sellerFee); // 返还卖家数量
        buyerBack = buyerPledge.sub(price.mul(amount)).sub(buyerFee); // 返还买家数量

        return (sellerFee, buyerFee, sellerBack, buyerBack);
    }

    function confirmCancelCalculateFeesAndRefunds(
        uint256 buyerPledge,
        uint256 sellerPledge,
        uint256 price,
        uint256 amount,
        uint256 buyerRate,
        uint256 sellerRate,
        uint256 buyerEx
    )
        internal
        pure
        returns (
            uint256 buyerFee,
            uint256 sellerFee,
            uint256 sellerBack,
            uint256 buyerBack
        )
    {
        buyerFee = price.mul(amount).mul(buyerRate).div(10000);
        if (buyerEx < buyerFee) {
            buyerFee = buyerEx;
        }
        sellerFee = price.mul(amount).mul(sellerRate).div(10000);
        if (sellerPledge < sellerFee) {
            sellerFee = sellerPledge;
        }
        sellerBack = sellerPledge.sub(sellerFee);
        buyerBack = buyerPledge.sub(buyerFee);

        return (buyerFee, sellerFee, sellerBack, buyerBack);
    }

    function verifyByAddress(
        address _address
    ) internal returns (uint256 contractType) {
        bytes memory ownerOfData = abi.encodeWithSignature(
            "ownerOf(uint256)",
            0
        );
        (, bytes memory returnOwnerOfData) = _address.call{value: 0}(
            ownerOfData
        );
        if (returnOwnerOfData.length > 0) {
            return 721;
        } else {
            bytes memory totalSupplyData = abi.encodeWithSignature(
                "totalSupply()"
            );
            (, bytes memory returnTotalSupplyData) = _address.call{value: 0}(
                totalSupplyData
            );
            if (returnTotalSupplyData.length > 0) {
                return 20;
            } else {
                return 1155;
            }
        }
    }

    function validateStatus(Status status) internal pure {
        require(status != Status.Initial, "Status Initial");
        require(
            status != Status.ConsultCancelCompleted,
            "Status ConsultCancelCompleted"
        );
        require(status != Status.Completed, "Status Completed");
        require(
            status != Status.SellerCancelWithoutDuty,
            "Status SellerCancelWithoutDuty"
        );
        require(status != Status.SellerBreak, "Status SellerBreak");
    }
}