// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {LSSVMPair} from "./LSSVMPair.sol";
import {LSSVMPairERC20} from "./LSSVMPairERC20.sol";
import {ILSSVMPairERC721} from "./erc721/ILSSVMPairERC721.sol";
import {LSSVMPairERC1155} from "./erc1155/LSSVMPairERC1155.sol";
import {ILSSVMPairFactoryLike} from "./ILSSVMPairFactoryLike.sol";
import {CurveErrorCodes} from "./bonding-curves/CurveErrorCodes.sol";
import {ICurve} from "./bonding-curves/ICurve.sol";

/**
 * @dev Full-featured router to handle all swap types, with partial fill support
 */
contract VeryFastRouter {
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;

    uint256 private constant BASE = 1e18;

    // Bit shift amounts for _findMaxFillableAmtForBuy and _findMaxFillableAmtForSell
    uint256 private constant FEE_MULTIPLIER_SHIFT_AMOUNT = 160;
    uint256 private constant DELTA_SHIFT_AMOUNT = 128;

    ILSSVMPairFactoryLike public immutable factory;

    struct BuyOrderWithPartialFill {
        LSSVMPair pair;
        bool isERC721;
        uint256[] nftIds;
        uint256 maxInputAmount;
        uint256 ethAmount;
        uint256 expectedSpotPrice;
        uint256[] maxCostPerNumNFTs; // @dev This is zero-indexed, so maxCostPerNumNFTs[x] = max price we're willing to pay to buy x+1 NFTs
    }

    struct SellOrderWithPartialFill {
        LSSVMPair pair;
        bool isETHSell;
        bool isERC721;
        uint256[] nftIds;
        bool doPropertyCheck;
        bytes propertyCheckParams;
        uint128 expectedSpotPrice;
        uint256 minExpectedOutput;
        uint256[] minExpectedOutputPerNumNFTs;
    }

    struct Order {
        BuyOrderWithPartialFill[] buyOrders;
        SellOrderWithPartialFill[] sellOrders;
        address payable tokenRecipient;
        address nftRecipient;
        bool recycleETH;
    }

    struct PartialFillSellArgs {
        LSSVMPair pair;
        uint128 spotPrice;
        uint256 maxNumNFTs;
        uint256[] minOutputPerNumNFTs;
        uint256 protocolFeeMultiplier;
        uint256 nftId;
    }

    struct PartialFillSellHelperArgs {
        LSSVMPair pair;
        uint256[] minOutputPerNumNFTs;
        uint256 protocolFeeMultiplier;
        uint256 nftId;
        uint256 start;
        uint256 end;
        uint128 delta;
        uint128 spotPrice;
        uint256 feeMultiplier;
        uint256 pairTokenBalance;
        uint256 royaltyAmount;
        uint256 numItemsToFill;
        uint256 priceToFillAt;
    }

    error VeryFastRouter__InvalidPair();
    error VeryFastRouter__BondingCurveQuoteError();

    constructor(ILSSVMPairFactoryLike _factory) {
        factory = _factory;
    }

    /**
     * @dev Meant to be used as a client-side utility
     * @notice Given a pair and a number of items to buy, calculate the max price paid for 1 up to numNFTs to buy
     */
    function getNFTQuoteForBuyOrderWithPartialFill(
        LSSVMPair pair,
        uint256 numNFTs,
        uint256 slippageScaling,
        uint256 assetId
    ) external view returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](numNFTs);

        for (uint256 i; i < numNFTs;) {
            uint128 newSpotPrice = pair.spotPrice();
            uint128 newDelta = pair.delta();

            // Assume that i items have been bought and get the new params
            if (i != 0) {
                (newSpotPrice, newDelta) = _getNewPoolParamsAfterBuying(pair, i);
            }

            // Calculate price to purchase the remaining numNFTs - i items
            uint256 price = _getHypotheticalNewPoolParamsAfterBuying(pair, newSpotPrice, newDelta, numNFTs - i);

            (,, uint256 royaltyTotal) = pair.calculateRoyaltiesView(assetId, price);
            price += royaltyTotal;

            // Set the price to buy numNFTs - i items
            prices[numNFTs - i - 1] = price;

            unchecked {
                ++i;
            }
        }
        // Scale up by slippage amount
        if (slippageScaling != 0) {
            for (uint256 i; i < prices.length;) {
                prices[i] += (prices[i] * slippageScaling / 1e18);

                unchecked {
                    ++i;
                }
            }
        }

        return prices;
    }

    function _getNewPoolParamsAfterBuying(LSSVMPair pair, uint256 i)
        internal
        view
        returns (uint128 newSpotPrice, uint128 newDelta)
    {
        CurveErrorCodes.Error errorCode;
        (errorCode, newSpotPrice, newDelta,,,) = pair.bondingCurve().getBuyInfo(
            pair.spotPrice(), pair.delta(), i, pair.fee(), pair.factory().protocolFeeMultiplier()
        );
        if (errorCode != CurveErrorCodes.Error.OK) {
            revert VeryFastRouter__BondingCurveQuoteError();
        }
    }

    function _getHypotheticalNewPoolParamsAfterBuying(
        LSSVMPair pair,
        uint128 newSpotPrice,
        uint128 newDelta,
        uint256 num
    ) internal view returns (uint256 output) {
        CurveErrorCodes.Error errorCode;
        (errorCode,,, output,,) = pair.bondingCurve().getBuyInfo(
            newSpotPrice, newDelta, num, pair.fee(), pair.factory().protocolFeeMultiplier()
        );
        if (errorCode != CurveErrorCodes.Error.OK) {
            revert VeryFastRouter__BondingCurveQuoteError();
        }
    }

    function getPairBaseQuoteTokenBalance(LSSVMPair pair) public view returns (uint256 balance) {
        ILSSVMPairFactoryLike.PairVariant variant = pair.pairVariant();
        if (
            variant == ILSSVMPairFactoryLike.PairVariant.ERC721_ETH
                || variant == ILSSVMPairFactoryLike.PairVariant.ERC1155_ETH
        ) {
            balance = address(pair).balance;
        } else {
            balance = ERC20(LSSVMPairERC20(address(pair)).token()).balanceOf(address(pair));
        }
    }

    function _wrapUintAsArray(uint256 valueToWrap) internal pure returns (uint256[] memory) {
        uint256[] memory arr = new uint256[](1);
        arr[0] = valueToWrap;
        return arr;
    }

    /**
     * @dev Meant to be used as a client-side utility
     * @notice Given a pair and a number of items to sell, calculate the mininum output for selling 1 to numNFTs
     */
    function getNFTQuoteForSellOrderWithPartialFill(
        LSSVMPair pair,
        uint256 numNFTs,
        uint256 slippageScaling,
        uint256 nftId
    ) external view returns (uint256[] memory) {
        uint256[] memory outputAmounts = new uint256[](numNFTs);

        for (uint256 i; i < numNFTs;) {
            uint128 newSpotPrice = pair.spotPrice();
            uint128 newDelta = pair.delta();

            // Assume that i items have been sold and get the new params
            if (i != 0) {
                (newSpotPrice, newDelta) = _getNewPoolParamsAfterSelling(pair, i);
            }

            // Calculate output to sell the remaining numNFTs - i items, factoring in royalties and fees
            uint256 output = _getHypotheticalNewPoolParamsAfterSelling(pair, newSpotPrice, newDelta, numNFTs - i);
            (,, uint256 royaltyTotal) = pair.calculateRoyaltiesView(nftId, output);
            output -= royaltyTotal;

            outputAmounts[numNFTs - i - 1] = output;

            unchecked {
                ++i;
            }
        }
        // Scale down by slippage amount
        if (slippageScaling != 0) {
            for (uint256 i; i < outputAmounts.length;) {
                outputAmounts[i] -= (outputAmounts[i] * slippageScaling / 1e18);

                unchecked {
                    ++i;
                }
            }
        }
        return outputAmounts;
    }

    function _getNewPoolParamsAfterSelling(LSSVMPair pair, uint256 i)
        internal
        view
        returns (uint128 newSpotPrice, uint128 newDelta)
    {
        CurveErrorCodes.Error errorCode;
        (errorCode, newSpotPrice, newDelta,,,) = pair.bondingCurve().getSellInfo(
            pair.spotPrice(), pair.delta(), i, pair.fee(), pair.factory().protocolFeeMultiplier()
        );
        if (errorCode != CurveErrorCodes.Error.OK) {
            revert VeryFastRouter__BondingCurveQuoteError();
        }
    }

    function _getHypotheticalNewPoolParamsAfterSelling(
        LSSVMPair pair,
        uint128 newSpotPrice,
        uint128 newDelta,
        uint256 num
    ) internal view returns (uint256 output) {
        CurveErrorCodes.Error errorCode;
        (errorCode,,, output,,) = pair.bondingCurve().getSellInfo(
            newSpotPrice, newDelta, num, pair.fee(), pair.factory().protocolFeeMultiplier()
        );
        if (errorCode != CurveErrorCodes.Error.OK) {
            revert VeryFastRouter__BondingCurveQuoteError();
        }
    }

    /**
     * @dev Performs a batch of sells and buys, avoids performing swaps where the price is beyond
     * Handles selling NFTs for tokens or ETH
     * Handles buying NFTs with tokens or ETH,
     * @param swapOrder The struct containing all the swaps to be executed
     * @return results Indices [0..swapOrder.sellOrders.length-1] contain the actual output amounts of the
     * sell orders, indices [swapOrder.sellOrders.length..swapOrder.sellOrders.length+swapOrder.buyOrders.length-1]
     * contain the actual input amounts of the buy orders.
     */
    function swap(Order calldata swapOrder) external payable returns (uint256[] memory results) {
        uint256 ethAmount = msg.value;

        // Get protocol to reduce gas on the _findMaxFillableAmtForSell/_findMaxFillableAmtForBuy calls
        uint256 protocolFeeMultiplier = factory.protocolFeeMultiplier();

        results = new uint256[](swapOrder.buyOrders.length + swapOrder.sellOrders.length);

        // Go through each sell order
        for (uint256 i; i < swapOrder.sellOrders.length;) {
            SellOrderWithPartialFill calldata order = swapOrder.sellOrders[i];
            uint128 pairSpotPrice = order.pair.spotPrice();
            uint256 outputAmount;

            // If the spot price parameter seen is what we expect it to be...
            if (pairSpotPrice == order.expectedSpotPrice) {
                // If the pair is an ETH pair and we opt into recycling ETH, add the output to our total accrued
                if (order.isETHSell && swapOrder.recycleETH) {
                    // Pass in params for property checking if needed
                    // Then do the swap with the same minExpectedTokenOutput amount
                    if (order.doPropertyCheck) {
                        outputAmount = ILSSVMPairERC721(address(order.pair)).swapNFTsForToken(
                            order.nftIds,
                            order.minExpectedOutput,
                            payable(address(this)),
                            true,
                            msg.sender,
                            order.propertyCheckParams
                        );
                    } else {
                        outputAmount = order.pair.swapNFTsForToken(
                            order.nftIds, order.minExpectedOutput, payable(address(this)), true, msg.sender
                        );
                    }

                    // Accumulate ETH amount
                    ethAmount += outputAmount;
                }
                // Otherwise, all tokens or ETH received from the sale go to the token recipient
                else {
                    // Pass in params for property checking if needed
                    // Then do the swap with the same minExpectedTokenOutput amount
                    if (order.doPropertyCheck) {
                        outputAmount = ILSSVMPairERC721(address(order.pair)).swapNFTsForToken(
                            order.nftIds,
                            order.minExpectedOutput,
                            swapOrder.tokenRecipient,
                            true,
                            msg.sender,
                            order.propertyCheckParams
                        );
                    } else {
                        outputAmount = order.pair.swapNFTsForToken(
                            order.nftIds, order.minExpectedOutput, swapOrder.tokenRecipient, true, msg.sender
                        );
                    }
                }
            }
            // Otherwise we need to do some partial fill calculations first
            else {
                uint256 numItemsToFill;
                uint256 priceToFillAt;

                {
                    // Grab royalty for calc in _findMaxFillableAmtForSell
                    (,, uint256 royaltyAmount) = order.pair.calculateRoyaltiesView(
                        order.isERC721 ? order.nftIds[0] : LSSVMPairERC1155(address(order.pair)).nftId(), BASE
                    );

                    // Calculate the max number of items we can sell
                    (numItemsToFill, priceToFillAt) = _findMaxFillableAmtForSell(
                        order.pair,
                        pairSpotPrice,
                        order.minExpectedOutputPerNumNFTs,
                        protocolFeeMultiplier,
                        royaltyAmount
                    );
                }

                // If we can sell at least 1 item...
                if (numItemsToFill != 0) {
                    // If property checking is needed, do the property check swap
                    if (order.doPropertyCheck) {
                        outputAmount = ILSSVMPairERC721(address(order.pair)).swapNFTsForToken(
                            order.nftIds[:numItemsToFill],
                            priceToFillAt,
                            swapOrder.tokenRecipient,
                            true,
                            msg.sender,
                            order.propertyCheckParams
                        );
                    }
                    // Otherwise do a normal sell swap
                    else {
                        // Get subarray if ERC721
                        if (order.isERC721) {
                            outputAmount = order.pair.swapNFTsForToken(
                                order.nftIds[:numItemsToFill], priceToFillAt, swapOrder.tokenRecipient, true, msg.sender
                            );
                        }
                        // For 1155 swaps, wrap as number
                        else {
                            outputAmount = order.pair.swapNFTsForToken(
                                _wrapUintAsArray(numItemsToFill),
                                priceToFillAt,
                                swapOrder.tokenRecipient,
                                true,
                                msg.sender
                            );
                        }
                    }
                }
            }
            results[i] = outputAmount;

            unchecked {
                ++i;
            }
        }

        // Go through each buy order
        for (uint256 i; i < swapOrder.buyOrders.length;) {
            BuyOrderWithPartialFill calldata order = swapOrder.buyOrders[i];

            // @dev We use inputAmount to store the spot price temporarily before it's overwritten
            // (yes, it's gross)
            uint256 inputAmount = order.pair.spotPrice();

            // If the spot price parameter seen is what we expect it to be...
            if (inputAmount == order.expectedSpotPrice) {
                // Then do a direct swap for all items we want
                inputAmount = order.pair.swapTokenForSpecificNFTs{value: order.ethAmount}(
                    order.nftIds, order.maxInputAmount, swapOrder.nftRecipient, true, msg.sender
                );

                // Deduct ETH amount if it's an ETH swap
                if (order.ethAmount != 0) {
                    ethAmount -= inputAmount;
                }
            }
            // Otherwise, we need to do some partial fill calculations first
            else {
                uint256 numItemsToFill;
                uint256 priceToFillAt;

                {
                    (,, uint256 royaltyAmount) = order.pair.calculateRoyaltiesView(
                        order.isERC721 ? order.nftIds[0] : LSSVMPairERC1155(address(order.pair)).nftId(), BASE
                    );

                    // uint128(inputAmount) is safe because order.pair.spotPrice() returns uint128
                    (numItemsToFill, priceToFillAt) = _findMaxFillableAmtForBuy(
                        order.pair, uint128(inputAmount), order.maxCostPerNumNFTs, protocolFeeMultiplier, royaltyAmount
                    );
                }

                // Set inputAmount to be 0 (assuming we don't fully meet all criteria for a swap)
                inputAmount = 0;

                // Continue if we can fill at least 1 item
                if (numItemsToFill != 0) {
                    // Set ETH amount to send (is 0 if it's an ERC20 swap)
                    uint256 ethToSendForBuy;
                    if (order.ethAmount != 0) {
                        ethToSendForBuy = priceToFillAt;
                    }

                    // If ERC721 swap
                    if (order.isERC721) {
                        // Get list of actually valid ids to buy
                        uint256[] memory availableIds = _findAvailableIds(order.pair, numItemsToFill, order.nftIds);

                        // Only swap if there are valid IDs to buy
                        if (availableIds.length != 0) {
                            inputAmount = order.pair.swapTokenForSpecificNFTs{value: ethToSendForBuy}(
                                availableIds, priceToFillAt, swapOrder.nftRecipient, true, msg.sender
                            );
                        }
                    }
                    // If ERC1155 swap
                    else {
                        // The amount to buy is the min(numItemsToFill, erc1155.balanceOf(pair))
                        {
                            uint256 availableNFTs = IERC1155(order.pair.nft()).balanceOf(
                                address(order.pair), LSSVMPairERC1155(address(order.pair)).nftId()
                            );
                            numItemsToFill = numItemsToFill < availableNFTs ? numItemsToFill : availableNFTs;
                        }

                        // Only continue if we can fill for nonzero amount of items
                        if (numItemsToFill != 0) {
                            // Do the 1155 swap, with the modified amount to buy
                            inputAmount = order.pair.swapTokenForSpecificNFTs{value: ethToSendForBuy}(
                                _wrapUintAsArray(numItemsToFill),
                                priceToFillAt,
                                swapOrder.nftRecipient,
                                true,
                                msg.sender
                            );
                        }
                    }

                    // Deduct ETH amount if it's an ETH swap
                    if (order.ethAmount != 0) {
                        ethAmount -= inputAmount;
                    }
                }
            }
            // Store inputAmount in results
            results[i + swapOrder.sellOrders.length] = inputAmount;

            unchecked {
                ++i;
            }
        }

        // Send excess ETH back to token recipient
        if (ethAmount != 0) {
            payable(swapOrder.tokenRecipient).safeTransferETH(ethAmount);
        }
    }

    receive() external payable {}

    /**
     * Internal helper functions
     */

    /**
     *   @dev Performs a binary search to find the largest value where maxCostPerNumNFTs is still greater than
     *   the pair's bonding curve's getBuyInfo() value.
     *   @param pair The pair to calculate partial fill values for
     *   @param maxCostPerNumNFTs The user's specified maximum price to pay for filling a number of NFTs
     *   @param protocolFeeMultiplier The % set as protocol fee
     *   @param royaltyAmount Royalty amount assuming a cost of BASE, used for cheaper royalty calc
     *   @dev Note that maxPricesPerNumNFTs is 0-indexed
     */
    function _findMaxFillableAmtForBuy(
        LSSVMPair pair,
        uint128 spotPrice,
        uint256[] memory maxCostPerNumNFTs,
        uint256 protocolFeeMultiplier,
        uint256 royaltyAmount
    ) internal view returns (uint256 numItemsToFill, uint256 priceToFillAt) {
        // Set start and end indices
        uint256 start = 1;
        uint256 end = maxCostPerNumNFTs.length;

        // Cache current pair values
        uint128 delta = pair.delta();

        uint256 feeMultiplierAndBondingCurve =
            uint96(pair.fee()) << FEE_MULTIPLIER_SHIFT_AMOUNT | uint160(address(pair.bondingCurve()));

        // Perform binary search
        while (start <= end) {
            // uint256 numItems = (start + end)/2; (but we hard-code it below to avoid stack too deep)

            // We check the price to buy index + 1
            (
                CurveErrorCodes.Error error,
                /* newSpotPrice */
                ,
                /* newDelta */
                ,
                uint256 currentCost,
                /* tradeFee */
                ,
                /* protocolFee */
            ) = (ICurve(address(uint160(feeMultiplierAndBondingCurve)))).getBuyInfo(
                spotPrice,
                delta,
                (start + end) / 2,
                (feeMultiplierAndBondingCurve >> FEE_MULTIPLIER_SHIFT_AMOUNT),
                protocolFeeMultiplier
            );

            currentCost += currentCost * royaltyAmount / BASE;

            // If the bonding curve has a math error, or
            // If the current price is too expensive relative to our max cost,
            // then we recurse on the left half (i.e. less items)
            if (
                error != CurveErrorCodes.Error.OK || currentCost > maxCostPerNumNFTs[(start + end) / 2 - 1] /* this is the max cost we are willing to pay, zero-indexed */
            ) {
                end = (start + end) / 2 - 1;
            }
            // Otherwise, we recurse on the right half (i.e. more items)
            else {
                numItemsToFill = (start + end) / 2;
                start = (start + end) / 2 + 1;
                priceToFillAt = currentCost;
            }
        }
    }

    function _findMaxFillableAmtForSell(
        LSSVMPair pair,
        uint128 spotPrice,
        uint256[] memory minOutputPerNumNFTs,
        uint256 protocolFeeMultiplier,
        uint256 royaltyAmount
    ) internal view returns (uint256 numItemsToFill, uint256 priceToFillAt) {
        // Set start and end indices
        uint256 start = 1;
        uint256 end = minOutputPerNumNFTs.length;

        // Cache current pair values
        uint256 deltaAndPairTokenBalance;
        uint256 feeMultiplierAndBondingCurve;
        {
            uint128 delta = pair.delta();
            uint128 pairTokenBalance = uint128(getPairBaseQuoteTokenBalance(pair));
            deltaAndPairTokenBalance = uint256(delta) << DELTA_SHIFT_AMOUNT | pairTokenBalance;
        }
        {
            uint256 feeMultiplier = uint96(pair.fee());
            address bondingCurve = address(pair.bondingCurve());
            feeMultiplierAndBondingCurve = feeMultiplier << FEE_MULTIPLIER_SHIFT_AMOUNT | uint160(bondingCurve);
        }

        // Perform binary search
        while (start <= end) {
            // We check the price to sell index + 1
            (
                CurveErrorCodes.Error error,
                /* newSpotPrice */
                ,
                /* newDelta */
                ,
                uint256 currentOutput,
                /* tradeFee */
                ,
                /* protocolFee */
            ) = (ICurve(address(uint160(feeMultiplierAndBondingCurve)))).getSellInfo(
                spotPrice,
                // get delta from deltaAndPairTokenBalance
                uint128(deltaAndPairTokenBalance >> DELTA_SHIFT_AMOUNT),
                (start + end) / 2,
                // get feeMultiplier from feeMultiplierAndBondingCurve
                uint96(feeMultiplierAndBondingCurve >> FEE_MULTIPLIER_SHIFT_AMOUNT),
                protocolFeeMultiplier
            );
            currentOutput -= currentOutput * royaltyAmount / BASE;
            // If the bonding curve has a math error, or
            // if the current output is too low relative to our max output, or
            // if the current output is greater than the pair's token balance,
            // then we recurse on the left half (i.e. less items)
            if (
                error != CurveErrorCodes.Error.OK || currentOutput < minOutputPerNumNFTs[(start + end) / 2 - 1] /* this is the minimum output we are expecting from the sale, zero-indexed */
                    || currentOutput > (uint256(uint128(deltaAndPairTokenBalance)))
            ) {
                end = (start + end) / 2 - 1;
            }
            // Otherwise, we recurse on the right half (i.e. more items)
            else {
                numItemsToFill = (start + end) / 2;
                start = (start + end) / 2 + 1;
                priceToFillAt = currentOutput;
            }
        }
    }

    /**
     * @dev Checks ownership of all desired NFT IDs to see which ones are still fillable
     * @param pair The pair to check for ownership
     * @param maxIdsNeeded The maximum amount of NFTs we want, guaranteed to be up to potentialIds.length, but could be less
     * @param potentialIds The possible NFT IDs that the pair could own
     * @return idsToBuy Actual NFT IDs owned by the pair, guaranteed to be up to maxIdsNeeded length, but could be less
     */
    function _findAvailableIds(LSSVMPair pair, uint256 maxIdsNeeded, uint256[] memory potentialIds)
        internal
        view
        returns (uint256[] memory)
    {
        IERC721 nft = IERC721(pair.nft());
        uint256[] memory idsThatExist = new uint256[](maxIdsNeeded);
        uint256 numIdsFound;

        // Go through each potential ID, and check to see if it's still owned by the pair
        // If it is, record the ID
        for (uint256 i; i < maxIdsNeeded;) {
            if (nft.ownerOf(potentialIds[i]) == address(pair)) {
                idsThatExist[numIdsFound] = potentialIds[i];
                numIdsFound += 1;
            }

            unchecked {
                ++i;
            }
        }
        // If all ids were found, return the full id list
        if (numIdsFound == maxIdsNeeded) {
            return idsThatExist;
        }
        // Otherwise, we didn't find enough IDs, so we need to return a subset
        if (numIdsFound < maxIdsNeeded) {
            uint256[] memory allIdsFound = new uint256[](numIdsFound);
            for (uint256 i; i < numIdsFound;) {
                allIdsFound[i] = idsThatExist[i];

                unchecked {
                    ++i;
                }
            }
            return allIdsFound;
        }
        uint256[] memory emptyArr = new uint256[](0);
        return emptyArr;
    }

    /**
     * Restricted functions
     */

    /**
     * @dev Allows an ERC20 pair contract to transfer ERC20 tokens directly from
     * the sender, in order to minimize the number of token transfers. Only callable by an ERC20 pair.
     * @param token The ERC20 token to transfer
     * @param from The address to transfer tokens from
     * @param to The address to transfer tokens to
     * @param amount The amount of tokens to transfer
     */
    function pairTransferERC20From(ERC20 token, address from, address to, uint256 amount) external {
        // verify caller is a trusted ERC20 pair contract
        if (
            !(
                factory.isValidPair(msg.sender)
                    && factory.getPairTokenType(msg.sender) == ILSSVMPairFactoryLike.PairTokenType.ERC20
            )
        ) {
            revert VeryFastRouter__InvalidPair();
        }

        // transfer tokens to pair
        token.safeTransferFrom(from, to, amount);
    }

    /**
     * @dev Allows a pair contract to transfer ERC721 NFTs directly from
     * the sender, in order to minimize the number of token transfers. Only callable by a pair.
     * @param nft The ERC721 NFT to transfer
     * @param from The address to transfer tokens from
     * @param to The address to transfer tokens to
     * @param id The ID of the NFT to transfer
     */
    function pairTransferNFTFrom(IERC721 nft, address from, address to, uint256 id) external {
        // verify caller is a trusted pair contract
        if (
            !(
                factory.isValidPair(msg.sender)
                    && factory.getPairNFTType(msg.sender) == ILSSVMPairFactoryLike.PairNFTType.ERC721
            )
        ) {
            revert VeryFastRouter__InvalidPair();
        }

        // transfer NFTs to pair
        nft.transferFrom(from, to, id);
    }

    /**
     * @dev Allows a pair contract to transfer ERC1155 NFTs directly from
     * the sender, in order to minimize the number of token transfers. Only callable by a pair.
     * @param nft The ERC1155 NFT to transfer
     * @param from The address to transfer tokens from
     * @param to The address to transfer tokens to
     * @param ids The IDs of the NFT to transfer
     * @param amounts The amount of each ID to transfer
     */
    function pairTransferERC1155From(
        IERC1155 nft,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external {
        // verify caller is a trusted pair contract
        if (
            !(
                factory.isValidPair(msg.sender)
                    && factory.getPairNFTType(msg.sender) == ILSSVMPairFactoryLike.PairNFTType.ERC1155
            )
        ) {
            revert VeryFastRouter__InvalidPair();
        }

        // transfer NFTs to pair
        nft.safeBatchTransferFrom(from, to, ids, amounts, bytes(""));
    }
}