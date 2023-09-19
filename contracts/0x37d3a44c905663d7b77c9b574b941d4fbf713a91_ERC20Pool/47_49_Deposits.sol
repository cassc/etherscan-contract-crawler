// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import { Math } from '@openzeppelin/contracts/utils/math/Math.sol';

import { DepositsState } from '../../interfaces/pool/commons/IPoolState.sol';

import { _priceAt, MAX_FENWICK_INDEX } from '../helpers/PoolHelper.sol';

import { Maths } from './Maths.sol';

/**
    @title  Deposits library
    @notice Internal library containing common logic for deposits management.
    @dev    Implemented as `Fenwick Tree` data structure.
 */
library Deposits {

    /// @dev Max index supported in the `Fenwick` tree
    uint256 internal constant SIZE = 8192;

    /**
     *  @notice Increase a value in the FenwickTree at an index.
     *  @dev    Starts at leaf/target and moved up towards root
     *  @param  deposits_          Deposits state struct.
     *  @param  index_             The deposit index.
     *  @param  unscaledAddAmount_ The unscaled amount to increase deposit by.
     */
    function unscaledAdd(
        DepositsState storage deposits_,
        uint256 index_,
        uint256 unscaledAddAmount_
    ) internal {
        // price buckets are indexed starting at 0, Fenwick bit logic is more elegant starting at 1
        ++index_;

        // unscaledAddAmount_ is the raw amount to add directly to the value at index_, unaffected by the scale array
        // For example, to denote an amount of deposit added to the array, we would need to call unscaledAdd with
        // (deposit amount) / scale(index).  There are two reasons for this:
        // 1- scale(index) is often already known in the context of where unscaledAdd(..) is called, and we want to avoid
        //    redundant iterations through the Fenwick tree.
        // 2- We often need to precisely change the value in the tree, avoiding the rounding that dividing by scale(index).
        //    This is more relevant to unscaledRemove(...), where we need to ensure the value is precisely set to 0, but we
        //    also prefer it here for consistency.

        uint256 value;
        uint256 scaling;
        uint256 newValue;

        while (index_ <= SIZE) {
            value    = deposits_.values[index_];
            scaling  = deposits_.scaling[index_];

            // Compute the new value to be put in location index_
            newValue = value + unscaledAddAmount_;

            // Update unscaledAddAmount to propogate up the Fenwick tree
            // Note: we can't just multiply addAmount_ by scaling[i_] due to rounding
            // We need to track the precice change in values[i_] in order to ensure
            // obliterated indices remain zero after subsequent adding to related indices
            // if scaling==0, the actual scale value is 1, otherwise it is scaling
            if (scaling != 0) unscaledAddAmount_ = Maths.wmul(newValue, scaling) - Maths.wmul(value, scaling);

            deposits_.values[index_] = newValue;

            // traverse upwards through tree via "update" route
            index_ += lsb(index_);
        }
    }

    /**
     *  @notice Finds index and sum of first bucket that EXCEEDS the given sum
     *  @dev    Used in `LUP` and `MOMP` calculation
     *  @param  deposits_      Struct for deposits state.
     *  @param  targetSum_     The sum to find index for.
     *  @return sumIndex_      Smallest index where prefixsum greater than the sum.
     *  @return sumIndexSum_   Sum at index PRECEDING `sumIndex_`.
     *  @return sumIndexScale_ Scale of bucket PRECEDING `sumIndex_`.
     */
    function findIndexAndSumOfSum(
        DepositsState storage deposits_,
        uint256 targetSum_
    ) internal view returns (uint256 sumIndex_, uint256 sumIndexSum_, uint256 sumIndexScale_) {
        // i iterates over bits from MSB to LSB.  We check at each stage if the target sum is to the left or right of sumIndex_+i
        uint256 i  = 4096; // 1 << (_numBits - 1) = 1 << (13 - 1) = 4096
        uint256 runningScale = Maths.WAD;

        // We construct the target sumIndex_ bit by bit, from MSB to LSB.  lowerIndexSum_ always maintains the sum
        // up to the current value of sumIndex_
        uint256 lowerIndexSum;
        uint256 curIndex;
        uint256 value;
        uint256 scaling;
        uint256 scaledValue;

        while (i > 0) {
            // Consider if the target index is less than or greater than sumIndex_ + i
            curIndex = sumIndex_ + i;
            value    = deposits_.values[curIndex];
            scaling  = deposits_.scaling[curIndex];

            // Compute sum up to sumIndex_ + i
            scaledValue =
                lowerIndexSum +
                (
                    scaling != 0 ? Math.mulDiv(
                        runningScale * scaling,
                        value,
                        1e36
                    ) : Maths.wmul(runningScale, value)
                );

            if (scaledValue  < targetSum_) {
                // Target value is too small, need to consider increasing sumIndex_ still
                if (curIndex <= MAX_FENWICK_INDEX) {
                    // sumIndex_+i is in range of Fenwick prices.  Target index has this bit set to 1.  
                    sumIndex_ = curIndex;
                    lowerIndexSum = scaledValue;
                }
            } else {
                // Target index has this bit set to 0
                // scaling == 0 means scale factor == 1, otherwise scale factor == scaling
                if (scaling != 0) runningScale = Maths.floorWmul(runningScale, scaling);

                // Current scaledValue is <= targetSum_, it's a candidate value for sumIndexSum_
                sumIndexSum_   = scaledValue;
                sumIndexScale_ = runningScale;
            }
            // Shift i to next less significant bit
            i = i >> 1;
        }
    }

    /**
     *  @notice Finds index of passed sum. Helper function for `findIndexAndSumOfSum`.
     *  @dev    Used in `LUP` and `MOMP` calculation
     *  @param  deposits_ Deposits state struct.
     *  @param  sum_      The sum to find index for.
     *  @return sumIndex_ Smallest index where prefixsum greater than the sum.
     */
    function findIndexOfSum(
        DepositsState storage deposits_,
        uint256 sum_
    ) internal view returns (uint256 sumIndex_) {
        (sumIndex_,,) = findIndexAndSumOfSum(deposits_, sum_);
    }

    /**
     *  @notice Get least significant bit (`LSB`) of integer `i_`.
     *  @dev    Used primarily to decrement the binary index in loops, iterating over range parents.
     *  @param  i_  The integer with which to return the `LSB`.
     */
    function lsb(
        uint256 i_
    ) internal pure returns (uint256 lsb_) {
        if (i_ != 0) {
            // "i & (-i)"
            lsb_ = i_ & ((i_ ^ 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) + 1);
        }
    }

    /**
     *  @notice Scale values in the tree from the index provided, upwards.
     *  @dev    Starts at passed in node and increments through range parent nodes, and ends at `8192`.
     *  @param  deposits_ Deposits state struct.
     *  @param  index_    The index to start scaling from.
     *  @param  factor_   The factor to scale the values by.
     */
    function mult(
        DepositsState storage deposits_,
        uint256 index_,
        uint256 factor_
    ) internal {
        // price buckets are indexed starting at 0, Fenwick bit logic is more elegant starting at 1
        ++index_;

        uint256 sum;
        uint256 value;
        uint256 scaling;
        uint256 bit = lsb(index_);

        // Starting with the LSB of index, we iteratively move up towards the MSB of SIZE
        // Case 1:     the bit of index_ is set to 1.  In this case, the entire subtree below index_
        //             is scaled.  So, we include factor_ into scaling[index_], and remember in sum how much
        //             we increased the subtree by, so that we can use it in case we encounter 0 bits (below).
        // Case 2:     The bit of index_ is set to 0.  In this case, consider the subtree below the node
        //             index_+bit. The subtree below that is not entirely scaled, but it does contain the
        //             subtree what was scaled earlier.  Therefore: we need to increment it's stored value
        //             (in sum) which was set in a prior interation in case 1.
        while (bit <= SIZE) {
            if ((bit & index_) != 0) {
                // Case 1 as described above
                value   = deposits_.values[index_];
                scaling = deposits_.scaling[index_];

                // Calc sum, will only be stored in range parents of starting node, index_
                if (scaling != 0) {
                    // Note: we can't just multiply by factor_ - 1 in the following line, as rounding will
                    // cause obliterated indices to have nonzero values.  Need to track the actual
                    // precise delta in the value array
                    uint256 scaledFactor = Maths.wmul(factor_, scaling);

                    sum += Maths.wmul(scaledFactor, value) - Maths.wmul(scaling, value);

                    // Apply scaling to all range parents less then starting node, index_
                    deposits_.scaling[index_] = scaledFactor;
                } else {
                    // this node's scale factor is 1
                    sum += Maths.wmul(factor_, value) - value;
                    deposits_.scaling[index_] = factor_;
                }
                // Unset the bit in index to continue traversing up the Fenwick tree
                index_ -= bit;
            } else {
                // Case 2 above.  superRangeIndex is the index of the node to consider that
                //                contains the sub range that was already scaled in prior iteration
                uint256 superRangeIndex = index_ + bit;

                value   = (deposits_.values[superRangeIndex] += sum);
                scaling = deposits_.scaling[superRangeIndex];

                // Need to be careful due to rounding to propagate actual changes upwards in tree.
                // sum is always equal to the actual value we changed deposits_.values[] by
                if (scaling != 0) sum = Maths.wmul(value, scaling) - Maths.wmul(value - sum, scaling);
            }
            // consider next most significant bit
            bit = bit << 1;
        }
    }

    /**
     *  @notice Get prefix sum of all indexes from provided index downwards.
     *  @dev    Starts at tree root and decrements through range parent nodes summing from index `sumIndex_`'s range to index `0`.
     *  @param  deposits_  Deposits state struct.
     *  @param  sumIndex_  The index to receive the prefix sum.
     *  @param  sum_       The prefix sum from current index downwards.
     */
    function prefixSum(
        DepositsState storage deposits_,
        uint256 sumIndex_
    ) internal view returns (uint256 sum_) {
        // price buckets are indexed starting at 0, Fenwick bit logic is more elegant starting at 1
        ++sumIndex_;

        uint256 runningScale = Maths.WAD; // Tracks scale(index_) as we move down Fenwick tree
        uint256 j            = SIZE;      // bit that iterates from MSB to LSB
        uint256 index        = 0;         // build up sumIndex bit by bit

        // Used to terminate loop.  We don't need to consider final 0 bits of sumIndex_
        uint256 indexLSB = lsb(sumIndex_);
        uint256 curIndex;

        while (j >= indexLSB) {
            curIndex = index + j;

            // Skip considering indices outside bounds of Fenwick tree
            if (curIndex > SIZE) continue;

            // We are considering whether to include node index + j in the sum or not.  Either way, we need to scaling[index + j],
            // either to increment sum_ or to accumulate in runningScale
            uint256 scaled = deposits_.scaling[curIndex];

            if (sumIndex_ & j != 0) {
                // node index + j of tree is included in sum
                uint256 value = deposits_.values[curIndex];

                // Accumulate in sum_, recall that scaled==0 means that the scale factor is actually 1
                sum_  += scaled != 0 ? Math.mulDiv(
                    runningScale * scaled,
                    value,
                    1e36
                ) : Maths.wmul(runningScale, value);

                // Build up index bit by bit
                index = curIndex;

                // terminate if we've already matched sumIndex_
                if (index == sumIndex_) break;
            } else {
                // node is not included in sum, but its scale needs to be included for subsequent sums
                if (scaled != 0) runningScale = Maths.floorWmul(runningScale, scaled);
            }
            // shift j to consider next less signficant bit
            j = j >> 1;
        }
    }

    /**
     *  @notice Decrease a node in the `FenwickTree` at an index.
     *  @dev    Starts at leaf/target and moved up towards root.
     *  @param  deposits_             Deposits state struct.
     *  @param  index_                The deposit index.
     *  @param  unscaledRemoveAmount_ Unscaled amount to decrease deposit by.
     */
    function unscaledRemove(
        DepositsState storage deposits_,
        uint256 index_,
        uint256 unscaledRemoveAmount_
    ) internal {
        // price buckets are indexed starting at 0, Fenwick bit logic is more elegant starting at 1
        ++index_;

        // We operate with unscaledRemoveAmount_ here instead of a scaled quantity to avoid duplicate computation of scale factor
        // (thus redundant iterations through the Fenwick tree), and ALSO so that we can set the value of a given deposit exactly
        // to 0.
        
        while (index_ <= SIZE) {
            // Decrement deposits_ at index_ for removeAmount, storing new value in value
            uint256 value   = (deposits_.values[index_] -= unscaledRemoveAmount_);
            uint256 scaling = deposits_.scaling[index_];

            // If scale factor != 1, we need to adjust unscaledRemoveAmount by scale factor to adjust values further up in tree
            // On the line below, it would be tempting to replace this with:
            // unscaledRemoveAmount_ = Maths.wmul(unscaledRemoveAmount, scaling).  This will introduce nonzero values up
            // the tree due to rounding.  It's important to compute the actual change in deposits_.values[index_]
            // and propogate that upwards.
            if (scaling != 0) unscaledRemoveAmount_ = Maths.wmul(value + unscaledRemoveAmount_, scaling) - Maths.wmul(value,  scaling);

            // Traverse upward through the "update" path of the Fenwick tree
            index_ += lsb(index_);
        }
    }

    /**
     *  @notice Scale tree starting from given index.
     *  @dev    Starts at leaf/target and moved up towards root.
     *  @param  deposits_ Deposits state struct.
     *  @param  index_    The deposit index.
     *  @return scaled_   Scaled value.
     */
    function scale(
        DepositsState storage deposits_,
        uint256 index_
    ) internal view returns (uint256 scaled_) {
        // price buckets are indexed starting at 0, Fenwick bit logic is more elegant starting at 1
        ++index_;

        // start with scaled_1 = 1
        scaled_ = Maths.WAD;
        while (index_ <= SIZE) {
            // Traverse up through Fenwick tree via "update" path, accumulating scale factors as we go
            uint256 scaling = deposits_.scaling[index_];
            // scaling==0 means actual scale factor is 1
            if (scaling != 0) scaled_ = Maths.wmul(scaled_, scaling);
            index_ += lsb(index_);
        }
    }

    /**
     *  @notice Returns sum of all deposits.
     *  @param  deposits_ Deposits state struct.
     *  @return Sum of all deposits in tree.
     */
    function treeSum(
        DepositsState storage deposits_
    ) internal view returns (uint256) {
        // In a scaled Fenwick tree, sum is at the root node and never scaled
        return deposits_.values[SIZE];
    }

    /**
     *  @notice Returns deposit value for a given deposit index.
     *  @param  deposits_     Deposits state struct.
     *  @param  index_        The deposit index.
     *  @return depositValue_ Value of the deposit.
     */
    function valueAt(
        DepositsState storage deposits_,
        uint256 index_
    ) internal view returns (uint256 depositValue_) {
        // Get unscaled value at index and multiply by scale
        depositValue_ = Maths.wmul(unscaledValueAt(deposits_, index_), scale(deposits_,index_));
    }

    /**
     *  @notice Returns unscaled (deposit without interest) deposit value for a given deposit index.
     *  @param  deposits_             Deposits state struct.
     *  @param  index_                The deposit index.
     *  @return unscaledDepositValue_ Value of unscaled deposit.
     */
    function unscaledValueAt(
        DepositsState storage deposits_,
        uint256 index_
    ) internal view returns (uint256 unscaledDepositValue_) {
        // In a scaled Fenwick tree, sum is at the root node, but needs to be scaled
        ++index_;

        uint256 j = 1;

        // Returns the unscaled value at the node.  We consider the unscaled value for two reasons:
        // 1- If we want to zero out deposit in bucket, we need to subtract the exact unscaled value
        // 2- We may already have computed the scale factor, so we can avoid duplicate traversal

        unscaledDepositValue_ = deposits_.values[index_];
        uint256 curIndex;
        uint256 value;
        uint256 scaling;

        while (j & index_ == 0) {
            curIndex = index_ - j;

            value   = deposits_.values[curIndex];
            scaling = deposits_.scaling[curIndex];

            unscaledDepositValue_ -= scaling != 0 ? Maths.wmul(scaling, value) : value;
            j = j << 1;
        }
    }

    /**
     *  @notice Returns `LUP` for a given debt value (capped at min bucket price).
     *  @param  deposits_ Deposits state struct.
     *  @param  debt_     The debt amount to calculate `LUP` for.
     *  @return `LUP` for given debt.
     */
    function getLup(
        DepositsState storage deposits_,
        uint256 debt_
    ) internal view returns (uint256) {
        return _priceAt(findIndexOfSum(deposits_, debt_));
    }
}