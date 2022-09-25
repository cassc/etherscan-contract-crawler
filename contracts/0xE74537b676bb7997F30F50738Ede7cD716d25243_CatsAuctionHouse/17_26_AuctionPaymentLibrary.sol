// SPDX-License-Identifier: GPL-3.0

//     `..        `.  `... `......`.. ..
//  `..   `..    `. ..     `..  `..    `..
// `..          `.  `..    `..   `..
// `..         `..   `..   `..     `..
// `..        `...... `..  `..        `..
//  `..   `..`..       `.. `..  `..    `..
//    `.... `..         `..`..    `.. ..
pragma solidity 0.8.16;

import { ICatsAuctionHouse } from "./ICatsAuctionHouse.sol";
import { ICatcoin } from "../catcoin/ICatcoin.sol";
import { CatsAuctionHouseStorage } from "./CatsAuctionHouseStorage.sol";
import { IERC20 } from "@solidstate/contracts/token/ERC20/IERC20.sol";
import { IWETH } from "../weth/IWETH.sol";

library AuctionPaymentLibrary {
    /**
     * @notice Checks if a bid is valid for the supplied auction
     */
    function isBidValid(ICatsAuctionHouse.Auction memory auction, uint256 bidAmount)
        internal
        view
        returns (bool, string memory)
    {
        if (isBelowReservePrice(auction, bidAmount)) return (false, "Bid is below reserve price");
        if (isBelowMinBid(auction, bidAmount)) return (false, "Bid price is below minimum");

        if (auction.isETH) {
            if (msg.value != bidAmount) {
                return (false, "Value sent doesn't match bid");
            }
        } else {
            if (ICatcoin(address(this)).balanceOf(msg.sender) < bidAmount)
                return (false, "Catcoin balance is not enough");
        }
        return (true, "");
    }

    function isBelowMinBid(ICatsAuctionHouse.Auction memory auction, uint256 bidAmount)
        internal
        view
        returns (bool valid)
    {
        if (auction.isETH) {
            valid =
                bidAmount <
                auction.amount + ((auction.amount * CatsAuctionHouseStorage.layout().minBidIncrementPercentage) / 100);
        } else {
            valid = bidAmount < auction.amount + CatsAuctionHouseStorage.layout().minBidIncrementUnit;
        }
    }

    function isBelowReservePrice(ICatsAuctionHouse.Auction memory auction, uint256 bidAmount)
        internal
        view
        returns (bool valid)
    {
        if (auction.isETH) {
            valid = bidAmount < CatsAuctionHouseStorage.layout().reservePriceInETH;
        } else {
            valid = bidAmount < CatsAuctionHouseStorage.layout().reservePriceInCatcoins;
        }
    }

    /**
     * @notice Transfer ETH or Catcoins to the address supplied. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     */
    function withdraw(
        ICatsAuctionHouse.Auction memory auction,
        address to,
        uint256[] calldata tokenIds
    ) internal {
        if (auction.isETH) {
            if (!_safeTransferETH(to, auction.amount)) {
                IWETH(CatsAuctionHouseStorage.layout().weth).deposit{ value: auction.amount }();
                IERC20(CatsAuctionHouseStorage.layout().weth).transfer(to, auction.amount);
            }
        } else {
            require(tokenIds.length == auction.amount, "Withdrawal amount mismatch");
            ICatcoin(address(this)).safeBatchTransferFrom(auction.bidder, to, tokenIds);
        }
    }

    /**
     * @notice Refunds ETH for ETH based bids. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     *         Not required for Catcoin as we use non custodial bidding.
     */
    function reverseLastBid(ICatsAuctionHouse.Auction memory auction) internal {
        if (auction.isETH) {
            if (!_safeTransferETH(auction.bidder, auction.amount)) {
                IWETH(CatsAuctionHouseStorage.layout().weth).deposit{ value: auction.amount }();
                IERC20(CatsAuctionHouseStorage.layout().weth).transfer(auction.bidder, auction.amount);
            }
        }
    }

    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }
}