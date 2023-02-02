// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./reentrancyGuard.sol";
import "./whitelist.sol";
import "./owner.sol";
import "./assetManagement.sol";
import "./orderUtils.sol";
import "./utils.sol";

// Exception codes
// RS:E0 - ETH transfer failed
// RS:E1 - Address(0) is not allowed
// RS:E2 - Cannot overfill order
// RS:E3 - Order not partially fillable, must fill order exactly full
// RS:E4 - Order already filled
// RS:E5 - Swap tokens must differ
// RS:E6 - Order not fillable
// RS:E7 - Order signature invalid
// RS:E8 - Malformed ecdsa signature
// RS:E9 - Invalid ecdsa signature
// RS:E10 - Malformed pre-signature
// RS:E11 - toUint256_outOfBounds
// RS:E12 - Array lengths must match, orders and makerAmountsToSpend
// RS:E13 - Do not use takerTokenDistribution_custom for one single order, use takerTokenDistribution_even
// RS:E14 - Array lengths must match, orders and takerTokenDistributions
// RS:E15 - Orders must not involve the same maker & same tokens
// RS:E16 - Presigner must be valid
// RS:E17 - Must be owner
// RS:E18 - ReentrancyGuard: reentrant call
// RS:E19 - Can not approve allowance for 0x0
// RS:E20 - Not permitted to cancel order
// RS:E21 - Must be whitelisted Keeper
// RS:E22 - Must be whitelisted DexAggKeeper
// RS:E23 - maker not satisfied, partiallyFillable = true
// RS:E24 - maker not satisfied, partiallyFillable = false
// RS:E25 - RookSwap contract surplusToken balances must not decrease, including threshold
// RS:E26 - RookSwap contract otherToken balances must not decrease
// RS:E27 - Begin and expiry must be valid
// RS:E28 - surplusToken must be in all orders
// RS:E29 - otherToken must be in all orders
// RS:E30 - Must be whitelisted DexAggRouter
// RS:E31 - surplusToken and otherToken must differ
// RS:E32 - approveToken must be either surplusToken or otherToken

/**
 * @dev Keeper interface for the callback function to execute swaps.
 */
abstract contract Keeper
{
    function rookSwapExecution_s3gN(
        address rookSwapsMsgSender,
        uint256[] calldata makerAmountsSentByRook,
        bytes calldata data
    )
        external
        virtual
        returns (bytes memory keeperReturn);
}

/**
 * @title RookSwap - A token swapping protocol that enables users to receive MEV generated from their orders.
 * A keeper executes the order on behalf of the user and extracts the value created by the order to distribute back to the user.
 * Orders are signed and submitted to an off-chain orderbook, where keepers can bid for the right to execute.
 * Users don't have to pay gas to swap tokens, except for token allowance approvals.
 * @author Joey Zacherl - <[email protected]>

 * Note: Some critical public/external functions in this contract are appended with underscores and extra characters as a gas optimization
 * Example: function() may become function_xyz() or function__abc()
 */
contract RookSwap is
    ReentrancyGuard,
    Owner,
    AssetManagement,
    Whitelist,
    OrderUtils
{
    using Address for address;
    using SafeERC20 for IERC20;
    using LibBytes for bytes;

    /**
     * @notice Keeper Swap function
     * @dev Facilitate swaps using Keeper's calldata through Keeper's custom trading contract.
     * Must be a whitelisted Keeper.
     * @param orders The orders to fill
     * @param makerAmountsToSpend makerAmounts to fill, correspond with orders
     * @param keeperTaker Keeper's taker address which will execute the swap, typically a trading contract. Must implement rookSwapExecution_s3gN.
     * @param data Keeper's calldata to pass into their rookSwapExecution_s3gN implementation.
     * This calldata is responsible for facilitating trade and paying the maker back in
     * takerTokens, or else the transaction will revert.
     * @return keeperReturn Return the Keeper's keeperCallData return value from rookSwapExecution_s3gN.
     * They'll likey want this for simulations, it's up to the Keeper to decide what to return
     * to help with tx simulations.
     */
    function swapKeeper__oASr(
        Order[] calldata orders,
        uint256[] calldata makerAmountsToSpend,
        address keeperTaker,
        bytes calldata data
    )
        external
        nonReentrant
        returns (bytes memory keeperReturn)
    {
        // Only allow swap execution whitelisted Keepers
        require(
            getKeeperWhitelistPosition__2u3w(keeperTaker) != 0,
            "RS:E21"
        );

        LibData.MakerData[] memory makerData = _prepareSwapExecution(orders, makerAmountsToSpend, keeperTaker);

        // Call the keeper's rookSwapExecution_s3gN function to execute the swap
        // Keeper must satisfy the user based on the signed order within this callback execution
        // We are passing in msg.sender to the keeper's rookSwapExecution_s3gN function.
        // We have ensured that keeperTaker is a whitelisted Rook keeper
        // but we have not ensured that msg.sender is keeperTaker's EOA
        // Keeper is responsible for ensuring that the msg.sender we pass them is their EOA and in their personal whitelist
        // Keeper is also responsible for ensuring that only a valid RookSwap contract can call their rookSwapExecution_s3gN function
        // This RookSwap contract is NOT upgradeable, so you can trust that the msg.sender we're passing along to Keeper is safe and correct
        keeperReturn = Keeper(keeperTaker).rookSwapExecution_s3gN(msg.sender, makerAmountsToSpend, data);

        _finalizeSwapExecution(orders, makerAmountsToSpend, makerData, keeperTaker);
    }

    /**
     * @dev Facilitate swaps using DexAgg Keeper's calldata through this contract.
     * Must be a whitelisted DexAgg Keeper.
     * @param orders The orders to fill.
     * @param makerAmountsToSpend makerAmounts to fill, correspond with orders.
     * @param makerWeights Mathematical weight for distributing tokens to makers.
     * moved this math off chain to save gas and simplify on chain computation.
     * corresponds with orders.
     * @param swap Execution calldata for facilitating a swap via DEX Aggregators right here on this contract.
     * If this function fails to pay back the maker in takerTokens, the transaction will revert.
     * @param takerTokenDistributions Quantities for distributing tokens to makers.
     * moved this math off chain to save gas and simplify on chain computation.
     * corresponds with orders.
     * @param metaData Supplementary data for swap execution and how to handle surplusTokens.
     * @return surplusAmount Amount of surplusTokens acquired during swap execution.
     */
    function swapDexAggKeeper_8B77(
        Order[] calldata orders,
        uint256[] calldata makerAmountsToSpend,
        uint256[] calldata makerWeights,
        LibSwap.DexAggSwap calldata swap,
        uint256[] calldata takerTokenDistributions,
        LibSwap.MetaData calldata metaData
    )
        external
        nonReentrant
        returns (uint256 surplusAmount)
    {
        // Only allow swap execution whitelisted DexAggKeepers
        require(
            getDexAggKeeperWhitelistPosition_IkFc(msg.sender) != 0,
            "RS:E22"
        );

        // Only allow swap execution on whitelisted DexAggs
        require(
            getDexAggRouterWhitelistPosition_ZgLC(swap.router) != 0,
            "RS:E30"
        );

        // surplusToken and otherToken must differ
        require(
            metaData.surplusToken != metaData.otherToken,
            "RS:E31"
        );

        // surplusToken and otherToken must be in every order, meaning there can only be 2 unique tokens in the swap.
        // otherwise this is an unsupported type of batching, or there is a logic bug with the dexAggKeeper offchain logic.
        // This check may not be necessary, but it's good to reject types of batching that are not supported today.
        // Reverting here will help prevent bugs and undesired behaviors.
        for (uint256 i; i < orders.length;)
        {
            require(
                metaData.surplusToken == orders[i].makerToken || metaData.surplusToken == orders[i].takerToken,
                "RS:E28"
            );
            require(
                metaData.otherToken == orders[i].takerToken || metaData.otherToken == orders[i].makerToken,
                "RS:E29"
            );

            // Gas optimization
            unchecked
            {
                ++i;
            }
        }

        LibData.ContractData memory contractData = LibData.ContractData(
            IERC20(metaData.surplusToken).balanceOf(address(this)),
            0,
            IERC20(metaData.otherToken).balanceOf(address(this))
        );
        LibData.MakerData[] memory makerData = _prepareSwapExecution(orders, makerAmountsToSpend, address(this));

        // Begin the swap execution by performing swaps on DexAggs
        uint256 takerTokenAmountToDistribute = _beginDexAggSwapExecution(
            swap,
            metaData
        );

        // Complete the swap execution by distributing takerTokens properly
        if (metaData.takerTokenDistributionType == LibSwap.TakerTokenDistributionType.Even)
        {
            _completeDexAggSwapExecution_takerTokenDistribution_even(
                orders,
                makerWeights,
                takerTokenAmountToDistribute
            );
        }
        else // elif (metaData.takerTokenDistributionType == LibSwap.TakerTokenDistributionType.Custom)
        {
            _completeDexAggSwapExecution_takerTokenDistribution_custom(
                orders,
                takerTokenDistributions
            );
        }

        _finalizeSwapExecution(orders, makerAmountsToSpend, makerData, msg.sender);

        // Return the amount of surplus retained
        surplusAmount = _finalizeSwapExecution_dexAggKeeper(contractData, metaData);
    }

    /**
     * @dev Prepare for swap execution by doing math, validating orders, and
     * transferring makerTokens from the maker to the Keeper which will be facilitating swaps.
     */
    function _prepareSwapExecution(
        Order[] calldata orders,
        uint256[] calldata makerAmountsToSpend,
        address makerTokenRecipient
    )
        private
        returns (LibData.MakerData[] memory makerData)
    {
        uint256 ordersLength = orders.length;
        require(
            ordersLength == makerAmountsToSpend.length,
            "RS:E12"
        );

        makerData = new LibData.MakerData[](ordersLength);
        for (uint256 i; i < ordersLength;)
        {
            // RookSwap does not currently support batching together swaps where 2 or more of the orders have the same maker & same tokens
            // This could be supported, however the gas efficiency would be horrible
            // because we'd have to use mappings and storage which costs a lot of gas
            // If you want to batch together orders in this way, it's still supported if you
            // by simply calling the RookSwap's swap function separately.
            // Example:
            //  call (RookSwap).swapKeeper([order1, order2, order3])
            //  then immediately after call (RookSwap).swapKeeper([order4, order5, order6])
            //  In this example let's assume that order1 and order4 include the same maker & tokens, so they had to be in separate function calls
            //  examples of order1 and order4
            //      Order1: Maker0x1234 swapping 900 DAI -> 0.6 WETH
            //      Order4: Maker0x1234 swapping 900 DAI -> 0.6 WETH
            // The reason for this is that _finalizeSwapExecution would be exposed to an exploit
            // if it attempted to process them in one single function call
            // And if we do process it securely in one signle function call, gas efficiency suffers beyond recovery.

            //  examples of order1 and order4
            //      Order1: Maker0x1234 swapping 0.6 WETH -> 900 DAI
            //      Order4: Maker0x1234 swapping 900 DAI -> 0.6 WETH

            //  examples of order1 and order5
            //      Order1: Maker0x1234 swapping 0.6 WETH -> 900 DAI
            //      Order5: Maker0x1234 swapping 900 DAI -> 900 USDC

            for (uint256 j; j < ordersLength;)
            {
                if (i != j && orders[i].maker == orders[j].maker &&
                    (orders[i].takerToken == orders[j].takerToken || orders[i].makerToken == orders[j].takerToken))
                {
                    revert("RS:E15");
                }

                // Gas optimization
                unchecked
                {
                    ++j;
                }
            }

            bytes32 orderHash = getOrderHash(orders[i]);
            // makerData[i] = orders[i].data._decodeData(orderHash);
            makerData[i] = _decodeData(orders[i].data, orderHash);
            // Set the balance in the makerData
            makerData[i].takerTokenBalance_before = IERC20(orders[i].takerToken).balanceOf(orders[i].maker);

            // We are calling this with doGetActualFillableMakerAmount = false as a gas optimization
            // and with doRevertOnFailure = true because we expect it to revert if the order is not fillable
            // We don't care about making that extra gas consuming calls
            // The only reason we're calling this function, is to validate the order
            _validateAndGetOrderRelevantStatus(orders[i], orderHash, makerData[i], true, false);

            // Transfer makers makerToken to the keeper to begin trade execution
            IERC20(orders[i].makerToken).safeTransferFrom(orders[i].maker, makerTokenRecipient, makerAmountsToSpend[i]);

            // Update makerAmountFilled now that the makerTokens have been spent
            // The tx will revert if the maker isn't paid back takerTokens based on the order they signed
            _updateMakerAmountFilled(
                orders[i].makerAmount,
                orderHash,
                makerAmountsToSpend[i],
                makerData[i].partiallyFillable
            );

            // Gas optimization
            unchecked
            {
                ++i;
            }
        }
    }

    /**
     * @dev Begin executing swap for DexAgg Keeper by executing the swap's calldata on the DexAgg.
     * Also calculate the amount of tokens we need to distribute.
     */
    function _beginDexAggSwapExecution(
        LibSwap.DexAggSwap calldata swap,
        LibSwap.MetaData calldata metaData
    )
        private
        returns (uint256 takerTokenAmountToDistribute)
    {
        // Begin swap execution by executing the swap on the DexAgg
        takerTokenAmountToDistribute = _dexAggKeeperSwap(swap, metaData);

        if (metaData.surplusTokenIsSwapTakerToken)
        {
            // With regards to a custom takerToken distribution
            // SurplusAmount could be extracted both from the makerToken and takerToken of a batched swap
            // Example: from the makerToken of User1's swap and the takerToken of User2's swap.
            // In this case User1 and User2 are sharing the tx gas fee.
            // So in this case, surplusAmountWithheld is only a fraction of the entire tx gas fee
            // And that's okay because this logic doesn't care about the other fraction of the tx gas fee
            // that was extracted at the beginning of the tx

            // Deduct the txs gas fee from the takerTokenAmountToDistribute because it's the surplusToken
            takerTokenAmountToDistribute = takerTokenAmountToDistribute - metaData.surplusAmountWithheld;
        }
    }

    /**
     * @dev Complete DexAgg Keeper swap execution by distributing the takerTokens evenly among all makers in the batch.
     * This function supports on chain positive slippage by utilizing the makerWeights and some simple math.
     */
    function _completeDexAggSwapExecution_takerTokenDistribution_even(
        Order[] calldata orders,
        uint256[] calldata makerWeights,
        uint256 takerTokenAmountToDistribute
    )
        private
    {
        uint256 ordersLength = orders.length;
        // Transfer takerToken to maker to complete trade
        // If statement here because we can save gas by not doing math if there's only 1 order in the batch
        // Otherwise we have to spend some gas on calculating the positive slippage for each user
        if (ordersLength == 1)
        {
            IERC20(orders[0].takerToken).safeTransfer(orders[0].maker, takerTokenAmountToDistribute);
        }
        else
        {
            // Determine how much to transfer to each maker in the batch
            for (uint256 i; i < ordersLength;)
            {
                IERC20(orders[i].takerToken).safeTransfer(orders[i].maker, takerTokenAmountToDistribute * makerWeights[i] / 1000000000000000000);

                // Gas optimization
                unchecked
                {
                    ++i;
                }
            }
        }
    }

    /**
     * @dev Complete DexAgg Keeper swap execution by distributing the takerTokens customly among all makers in the batch.
     * This function does NOT support on chain positive slippage as the math is determined off chain ahead of time.
     */
    function _completeDexAggSwapExecution_takerTokenDistribution_custom(
        Order[] calldata orders,
        uint256[] calldata takerTokenDistributions
    )
        private
    {
        // For all of our takerTokenDistributions,
        // Transfer takerToken to maker to complete trade

        // This function should only be called with 2 or more orders
        // If only 1 order is being processed, use evenTakerTokenDistribution instead
        uint256 ordersLength = orders.length;
        require(
            ordersLength > 1,
            "RS:E13"
        );

        // for every order, we must have an takerTokenDistribution
        require(
            ordersLength == takerTokenDistributions.length,
            "RS:E14"
        );

        for (uint256 i; i < ordersLength;)
        {
            IERC20(orders[i].takerToken).safeTransfer(orders[i].maker, takerTokenDistributions[i]);

            // Gas optimization
            unchecked
            {
                ++i;
            }
        }
    }

    /**
     * @dev Finalize swap execution by doing some math, verifying that each maker got paid, and emitting events.
     */
    function _finalizeSwapExecution(
        Order[] calldata orders,
        uint256[] calldata makerAmountsToSpend,
        LibData.MakerData[] memory makerData,
        address taker
    )
        private
    {
        // Require that all of the maker's swaps have been satisfied based on the order they signed
        for (uint256 i; i < orders.length;)
        {
            // Measure maker's post-trade balance
            makerData[i].takerTokenBalance_after = IERC20(orders[i].takerToken).balanceOf(orders[i].maker);

            // Validate order requirements
            uint256 takerAmountFilled = makerData[i].takerTokenBalance_after - makerData[i].takerTokenBalance_before;

            // Ensure the fill meets the maker's signed requirement
            // Gas optimization
            // if takerAmountDecayRate is zero, we can save gas by not calling _calculateCurrentTakerAmountMin
            // otherwise we must perform some extra calculations to determine currentTakerAmountMin
            uint256 currentTakerAmountMin =
                orders[i].takerAmountDecayRate == 0 ?
                orders[i].takerAmountMin :
                _calculateCurrentTakerAmountMin(
                    orders[i].takerAmountMin,
                    orders[i].takerAmountDecayRate, makerData[i]
                );
            if (makerData[i].partiallyFillable)
            {
                // If the order is partiallyFillable, we have to slightly alter our math to support checking this properly
                // We must factor in the ratio of the makerAmount we're actually spending against the order's full makerAmount
                // This is because the _calculateCurrentTakerAmountMin is always in terms of the order's full amount
                // OPTIMIZATION: I could store this in a variable to make the code cleaner, but that costs more gas
                // So I'm in-lining all this math to save on gas
                require(
                    takerAmountFilled * orders[i].makerAmount >= currentTakerAmountMin * makerAmountsToSpend[i],
                    "RS:E23"
                );
            }
            else
            {
                require(
                    takerAmountFilled >= currentTakerAmountMin,
                    "RS:E24"
                );
            }

            // Log the fill event
            emit Fill(
                orders[i].maker,
                taker,
                orders[i].makerToken,
                orders[i].takerToken,
                makerAmountsToSpend[i],
                takerAmountFilled,
                makerData[i].orderHash
            );

            // Gas optimization
            unchecked
            {
                ++i;
            }
        }
    }

    /**
     * @dev Finalize swap execution for the DexAgg Keeper by ensuring that this contract didn't lose value
     * and that all thresholds were satisfied.
     */
    function _finalizeSwapExecution_dexAggKeeper(
        LibData.ContractData memory contractData,
        LibSwap.MetaData calldata metaData
    )
        private
        view
        returns (uint256 surplusAmount)
    {
        // Measure post-trade balances
        contractData.surplusTokenBalance_after = IERC20(metaData.surplusToken).balanceOf(address(this));
        // Gas optimization
        // not setting a variable here since we only use it once
        // contractData.otherTokenBalance_after = IERC20(metaData.otherToken).balanceOf(address(this));

        // Require that the DexAggKeeper has been satisfied
        // Revert if the DexAggKeeper has lost value in surplusTokens or otherTokens
        // We expect to gain surplus in surplusTokens by metaData.surplusProtectionThreshold to cover the cost of gas and other fees
        // But we do not expect otherToken to increase
        // This protection is required so that we don't need to trust the DexAggs's calldata nearly as much

        // surplusToken must increase based on metaData.surplusProtectionThreshold, and should never decrease
        require(
            contractData.surplusTokenBalance_after >= (contractData.surplusTokenBalance_before + metaData.surplusProtectionThreshold),
            "RS:E25"
        );

        // otherToken must at least break even
        // Typically this balance will not increase, break even is normal
        require(
            IERC20(metaData.otherToken).balanceOf(address(this)) >= contractData.otherTokenBalance_before,
            "RS:E26"
        );

        surplusAmount = contractData.surplusTokenBalance_after - contractData.surplusTokenBalance_before;
    }

    /**
     * @dev Calculate the order's current takerAmountMin at this point in time.
     * The takerAmountDecayRate behaves like a dutch auction, as the takerAmount decays over time down to the takerAmountMin.
     * Setting the takerAmountDecayRate to zero disables this decay feature and the swapping price remains static.
     * Ideally, if takerAmountDecayRate is zero you don't even have to call this function because it just returns takerAmountMin.
     */
    function _calculateCurrentTakerAmountMin(
        uint256 takerAmountMin,
        uint256 takerAmountDecayRate,
        LibData.MakerData memory makerData
    )
        private
        view
        returns (uint256 currentTakerAmountMin)
    {
        // Saving gas by not creating variables for these
        // Leaving commented out variables here to help with readability
        // uint256 elapsedTime = block.timestamp - makerData.begin;
        // uint256 totalTime = makerData.expiry - makerData.begin;
        // uint256 timestamp = block.timestamp >= makerData.begin ? block.timestamp : makerData.begin;
        // uint256 multiplier  = block.timestamp < makerData.expiry ? makerData.expiry - timestamp: 0;
        // currentTakerAmountMin = takerAmountMin + (takerAmountDecayRate * multiplier);

        // Gas optimization
        // Saving gas by not creating variables for any of this.
        // The code is increidbly hard to read, but it saves a lot of gas
        // The more readable version of the code is commented out above
        currentTakerAmountMin =
            takerAmountMin + (takerAmountDecayRate * (
                block.timestamp < makerData.expiry
                    ?
                    makerData.expiry - (
                        block.timestamp >= makerData.begin
                            ?
                            block.timestamp
                            :
                            makerData.begin
                        )
                    :
                    0
                )
            );
    }

    /**
     * @dev Execute the swap calldatas on the DexAggs. Also manage allowances to the DexAggs.
     */
    function _dexAggKeeperSwap(
        LibSwap.DexAggSwap memory swap,
        LibSwap.MetaData calldata metaData
    )
        private
        returns (uint256 swapOutput)
    {
        // Execute all requried allowance approvals before swapping
        // We will assume that the function caller knows which tokens need approved and which do not
        // We should be approving the token we're spending inside the swap.callData, if we don't this tx will likely revert
        // So it's up to the function caller to set this properly or else reverts can happen due to no allowance
        require(
            swap.approveToken != address(0),
            "RS:E19"
        );

        // approveToken must be either surplusToken or otherToken, to prevent arbitrary token allowance approvals
        require(
            swap.approveToken == metaData.surplusToken || swap.approveToken == metaData.otherToken,
            "RS:E32"
        );

        // Approve exactly how much we intend to swap on the DexAgg
        IERC20(swap.approveToken).approve(swap.router, swap.approvalAmount);

        // Execute the calldata
        (bool success, bytes memory returnData) = swap.router.call{ value: 0 }(swap.callData);
        _verifyCallResult(success, returnData, "callData execution failed");
        swapOutput = returnData.toUint256(0);

        // Revoke the DexAgg's allowance now that the swap has finished
        IERC20(swap.approveToken).approve(swap.router, 0);
    }

    /**
     * @dev Verify the result of a call
     * This function reverts and bubbles up an error code if there's a problem
     * The return value doesn't matter, the function caller should already have the call's result
     */
    function _verifyCallResult(
        bool success,
        bytes memory returnData,
        string memory errorMessage
    )
        private
        pure
    {
        if (success)
        {
            // Nothing needs done, just return
            return;
        }
        else
        {
            // Look for revert reason and bubble it up if present
            if (returnData.length != 0)
            {
                // The easiest way to bubble the revert reason is using memory via assembly
                assembly
                {
                    let returnData_size := mload(returnData)
                    revert(add(32, returnData), returnData_size)
                }
            }
            else
            {
                revert(errorMessage);
            }
        }
    }
}