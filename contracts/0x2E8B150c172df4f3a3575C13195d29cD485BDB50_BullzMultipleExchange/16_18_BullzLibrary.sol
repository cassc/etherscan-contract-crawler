//  SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// add common transfer

// add ERC721/ERC1155 transfer helper

library BullzLibrary {
    using SafeMath for uint256;

    // compute the amount that must be sent to the platefom owner
    function computePlateformOwnerProfit(
        uint256 offerPrice,
        uint256 totalSentAmount,
        uint256 profitPercent
    ) internal pure returns (uint256 ownerProfitAmount, uint256 sellerAmount) {
        ownerProfitAmount = offerPrice.mul(profitPercent).div(100);
        sellerAmount = totalSentAmount.sub(ownerProfitAmount);
    }

    // extract the owner profit from the offer total amount
    function extractOwnerProfitFromOfferAmount(
        uint256 offerTotalAmount,
        uint256 ownerProfitAmount
    ) internal pure returns (uint256) {
        return offerTotalAmount.sub(ownerProfitAmount);
    }

    function extractPurshasedAmountFromOfferAmount(
        uint256 offerAmount,
        uint256 bidAmount
    ) internal pure returns (uint256) {
        return offerAmount.sub(bidAmount);
    }

    // compute the amount that must be sent to the platefom owner
    function computePlateformOwnerProfitByAmount(
        uint256 totalSentETH,
        uint256 offerPrice,
        uint256 nftAmount,
        uint256 profitPercent
    ) internal pure returns (uint256 ownerProfitAmount, uint256 sellerAmount) {
        ownerProfitAmount = (offerPrice.mul(nftAmount)).mul(profitPercent).div(
            100
        );
        require(
            totalSentETH >= (offerPrice.mul(nftAmount).add(ownerProfitAmount)),
            "Bullz: Insufficient funds"
        );
        sellerAmount = totalSentETH.sub(ownerProfitAmount);
    }
}