// SPDX-License-Identifier: BSL 1.1 - Blend (c) Non Fungible Trading Ltd.
pragma solidity 0.8.17;

import "lib/solmate/src/utils/SignedWadMath.sol";

import { InvalidRepayment } from "./lib/Errors.sol";
import "./lib/Structs.sol";
import "../pool/interfaces/IBlurPool.sol";
import { IBlurExchangeV2 as IExchangeV2 } from "../exchangeV2/interfaces/IBlurExchangeV2.sol";
import { Order as OrderV1, SignatureVersion, Side } from "../exchangeV1/lib/OrderStructs.sol";
import {
    TakeAskSingle,
    TakeBidSingle,
    FeeRate,
    Taker,
    Exchange,
    Order as OrderV2,
    AssetType
} from "../exchangeV2/lib/Structs.sol";

interface IExchange {
    function execute(Input calldata sell, Input calldata buy) external payable;
}

library Helpers {
    int256 private constant _YEAR_WAD = 365 days * 1e18;
    uint256 private constant _LIQUIDATION_THRESHOLD = 100_000;
    uint256 private constant _BASIS_POINTS = 10_000;

    error InvalidExecution();

    /**
     * @dev Computes the current debt of a borrow given the last time it was touched and the last computed debt.
     * @param amount Principal in ETH
     * @param startTime Start time of the loan
     * @param rate Interest rate (in bips)
     * @dev Formula: https://www.desmos.com/calculator/l6omp0rwnh
     */
    function computeCurrentDebt(
        uint256 amount,
        uint256 rate,
        uint256 startTime
    ) public view returns (uint256) {
        uint256 loanTime = block.timestamp - startTime;
        int256 yearsWad = wadDiv(int256(loanTime) * 1e18, _YEAR_WAD);
        return uint256(wadMul(int256(amount), wadExp(wadMul(yearsWad, bipsToSignedWads(rate)))));
    }

    /**
     * @dev Calculates the current maximum interest rate a specific refinancing
     * auction could settle at currently given the auction's start block and duration.
     * @param startBlock The block the auction started at
     * @param oldRate Previous interest rate (in bips)
     * @dev Formula: https://www.desmos.com/calculator/urasr71dhb
     */
    function calcRefinancingAuctionRate(
        uint256 startBlock,
        uint256 auctionDuration,
        uint256 oldRate
    ) public view returns (uint256) {
        uint256 currentAuctionBlock = block.number - startBlock;
        int256 oldRateWads = bipsToSignedWads(oldRate);

        uint256 auctionT1 = auctionDuration / 5;
        uint256 auctionT2 = (4 * auctionDuration) / 5;

        int256 maxRateWads;
        {
            int256 aInverse = -bipsToSignedWads(15000);
            int256 b = 2;
            int256 maxMinRateWads = bipsToSignedWads(500);

            if (oldRateWads < -((b * aInverse) / 2)) {
                maxRateWads = maxMinRateWads + (oldRateWads ** 2) / aInverse + b * oldRateWads;
            } else {
                maxRateWads = maxMinRateWads - ((b ** 2) * aInverse) / 4;
            }
        }

        int256 startSlope = maxRateWads / int256(auctionT1); // wad-bips per block

        int256 middleSlope = bipsToSignedWads(9000) / int256((3 * auctionDuration) / 5) + 1; // wad-bips per block (add one to account for rounding)
        int256 middleB = maxRateWads - int256(auctionT1) * middleSlope;

        if (currentAuctionBlock < auctionT1) {
            return signedWadsToBips(startSlope * int256(currentAuctionBlock));
        } else if (currentAuctionBlock < auctionT2) {
            return signedWadsToBips(middleSlope * int256(currentAuctionBlock) + middleB);
        } else if (currentAuctionBlock < auctionDuration) {
            int256 endSlope;
            int256 endB;
            {
                endSlope =
                    (bipsToSignedWads(_LIQUIDATION_THRESHOLD) -
                        ((int256(auctionT2) * middleSlope) + middleB)) /
                    int256(auctionDuration - auctionT2); // wad-bips per block
                endB =
                    bipsToSignedWads(_LIQUIDATION_THRESHOLD) -
                    int256(auctionDuration) *
                    endSlope;
            }

            return signedWadsToBips(endSlope * int256(currentAuctionBlock) + endB);
        } else {
            return _LIQUIDATION_THRESHOLD;
        }
    }

    /**
     * @dev Converts an integer bips value to a signed wad value.
     */
    function bipsToSignedWads(uint256 bips) public pure returns (int256) {
        return int256((bips * 1e18) / _BASIS_POINTS);
    }

    /**
     * @dev Converts a signed wad value to an integer bips value.
     */
    function signedWadsToBips(int256 wads) public pure returns (uint256) {
        return uint256((wads * int256(_BASIS_POINTS)) / 1e18);
    }

    function executeTakeBid(
        Lien calldata lien,
        uint256 lienId,
        ExecutionV1 calldata execution,
        uint256 debt,
        IBlurPool pool,
        IExchange exchange,
        address delegate,
        address matchingPolicy
    ) external {
        /* Create sell side order from Blend. */
        OrderV1 memory sellOrder = OrderV1({
            trader: address(this),
            side: Side.Sell,
            matchingPolicy: matchingPolicy,
            collection: address(lien.collection),
            tokenId: lien.tokenId,
            amount: 1,
            paymentToken: address(pool),
            price: execution.makerOrder.order.price,
            listingTime: execution.makerOrder.order.listingTime + 1, // listingTime determines maker/taker
            expirationTime: type(uint256).max,
            fees: new Fee[](0),
            salt: lienId, // prevent reused order hash
            extraParams: "\x01" // require oracle signature
        });
        Input memory sell = Input({
            order: sellOrder,
            v: 0,
            r: bytes32(0),
            s: bytes32(0),
            extraSignature: execution.extraSignature,
            signatureVersion: SignatureVersion.Single,
            blockNumber: execution.blockNumber
        });

        /* Execute marketplace order. */
        uint256 balanceBefore = pool.balanceOf(address(this));
        lien.collection.approve(delegate, lien.tokenId);
        exchange.execute(sell, execution.makerOrder);

        /* Determine the funds received from the sale (after fees). */
        uint256 amountReceivedFromSale = pool.balanceOf(address(this)) - balanceBefore;
        if (amountReceivedFromSale < debt) {
            revert InvalidRepayment();
        }

        /* Repay lender. */
        pool.transferFrom(address(this), lien.lender, debt);

        /* Send surplus to borrower. */
        unchecked {
            pool.transferFrom(address(this), lien.borrower, amountReceivedFromSale - debt);
        }
    }

    function executeTakeAskV2(
        LoanOffer calldata offer, 
        AskExecutionV2 calldata execution,
        uint256 loanAmount,
        uint256 collateralTokenId,
        uint256 price,
        IBlurPool pool,
        IExchangeV2 exchangeV2
    ) external {
        OrderV2 calldata order = execution.order;
        if (address(offer.collection) != order.collection || order.assetType != AssetType.ERC721) {
            revert InvalidExecution();
        }

        /* Transfer funds. */
        /* Need to retrieve the ETH to fund the marketplace execution. */
        if (loanAmount < price) {
            /* Take funds from lender. */
            pool.withdrawFrom(offer.lender, address(this), loanAmount);

            /* Supplement difference from borrower. */
            unchecked {
                pool.withdrawFrom(msg.sender, address(this), price - loanAmount);
            }
        } else {
            /* Take funds from lender. */
            pool.withdrawFrom(offer.lender, address(this), price);

            /* Send surplus to borrower. */
            unchecked {
                pool.transferFrom(offer.lender, msg.sender, loanAmount - price);
            }
        }

        TakeAskSingle memory execute = TakeAskSingle({
            order: execution.order,
            exchange: Exchange({
                index: 0,
                proof: execution.proof,
                listing: Listing({
                    index: execution.listing.index,
                    tokenId: collateralTokenId,
                    amount: 1,
                    price: price
                }),
                taker: Taker({ tokenId: collateralTokenId, amount: 1 })
            }),
            takerFee: FeeRate(address(0), 0),
            signature: execution.signature,
            tokenRecipient: address(this)
        });
        exchangeV2.takeAskSingle{ value: price }(execute, execution.oracleSignature);
    }

    function executeTakeAsk(
        LoanOffer calldata offer,
        ExecutionV1 calldata execution,
        uint256 loanAmount,
        uint256 collateralTokenId,
        uint256 price,
        IBlurPool pool,
        IExchange exchange,
        address matchingPolicy
    ) external {
        /* Transfer funds. */
        /* Need to retrieve the ETH to fund the marketplace execution. */
        if (loanAmount < price) {
            /* Take funds from lender. */
            pool.withdrawFrom(offer.lender, address(this), loanAmount);

            /* Supplement difference from borrower. */
            unchecked {
                pool.withdrawFrom(msg.sender, address(this), price - loanAmount);
            }
        } else {
            /* Take funds from lender. */
            pool.withdrawFrom(offer.lender, address(this), price);

            /* Send surplus to borrower. */
            unchecked {
                pool.transferFrom(offer.lender, msg.sender, loanAmount - price);
            }
        }

        OrderV1 memory buyOrder = OrderV1({
            trader: address(this),
            side: Side.Buy,
            matchingPolicy: matchingPolicy,
            collection: address(offer.collection),
            tokenId: collateralTokenId,
            amount: 1,
            paymentToken: address(0),
            price: price,
            listingTime: execution.makerOrder.order.listingTime + 1, // listingTime determines maker/taker
            expirationTime: type(uint256).max,
            fees: new Fee[](0),
            salt: uint160(execution.makerOrder.order.trader), // prevent reused order hash
            extraParams: "\x01" // require oracle signature
        });
        Input memory buy = Input({
            order: buyOrder,
            v: 0,
            r: bytes32(0),
            s: bytes32(0),
            extraSignature: execution.extraSignature,
            signatureVersion: SignatureVersion.Single,
            blockNumber: execution.blockNumber
        });

        /* Execute order using ETH currently in contract. */
        exchange.execute{ value: price }(execution.makerOrder, buy);
    }

    function executeTakeBidV2(
        Lien calldata lien,
        BidExecutionV2 calldata execution,
        uint256 debt,
        IBlurPool pool,
        IExchangeV2 exchangeV2,
        address delegateV2
    ) external {
        OrderV2 calldata order = execution.order;
        if (address(lien.collection) != order.collection || order.assetType != AssetType.ERC721) {
            revert InvalidExecution();
        }

        uint256 balanceBefore = pool.balanceOf(address(this));

        TakeBidSingle memory execute = TakeBidSingle({
            order: execution.order,
            exchange: Exchange({
                index: 0,
                proof: execution.proof,
                listing: execution.listing,
                taker: Taker({ tokenId: lien.tokenId, amount: 1 })
            }),
            takerFee: FeeRate(address(0), 0),
            signature: execution.signature
        });

        /* Execute marketplace order. */
        lien.collection.approve(delegateV2, lien.tokenId);
        exchangeV2.takeBidSingle(execute, execution.oracleSignature);

        /* Determine the funds received from the sale (after fees). */
        uint256 amountReceivedFromSale = pool.balanceOf(address(this)) - balanceBefore;
        if (amountReceivedFromSale < debt) {
            revert InvalidRepayment();
        }

        /* Repay lender. */
        pool.transferFrom(address(this), lien.lender, debt);

        /* Send surplus to borrower. */
        unchecked {
            pool.transferFrom(address(this), lien.borrower, amountReceivedFromSale - debt);
        }
    }
}