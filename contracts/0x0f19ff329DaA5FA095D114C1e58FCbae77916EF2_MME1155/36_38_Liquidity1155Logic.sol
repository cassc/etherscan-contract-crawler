// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {Pool1155Logic} from "./Pool1155Logic.sol";
import {MathHelpers} from "../libraries/MathHelpers.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Errors} from "../libraries/Errors.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {ILPToken} from "../interfaces/ILPToken.sol";

/**
 * @title library for Liquidity logic of 1155 pools with single collection
 * @author Souq.Finance
 * @notice Defines the logic functions for the AMM and MME that operate ERC1155 shares
 * @notice License: https://souq-nft-amm-v1.s3.amazonaws.com/LICENSE.md
 */

library Liquidity1155Logic {
    using SafeERC20 for IERC20;
    using Math for uint256;
    using Pool1155Logic for DataTypes.AMMSubPool1155[];
    /**
     * @dev Emitted when the user initiates deposit of stablecoins and shares into a subpool
     * @param user The user address
     * @param subPoolId The subPool id
     * @param stableIn The amount of stablecoin inputted
     * @param params The token ids[] and amounts[] structure
     * @param totalShares The new total shares count
     * @param F The new F
     */
    event DepositInitiated(
        address user,
        uint256 subPoolId,
        uint256 stableIn,
        DataTypes.Shares1155Params params,
        uint256 totalShares,
        uint256 F
    );
    /**
     * @dev Emitted when adding liquidity by a liqduity provider using stablecoins
     * @param stableIn The amount of stablecoin inputted
     * @param lpAmount The amount of LP token outputted
     * @param from The address of the msg sender
     * @notice it's here to avoid the stack too deep issue for now
     */
    event AddedLiqStable(uint256 stableIn, uint256 lpAmount, address from);

    /**
     * @dev Emitted when adding liquidity by a liqduity provider using shares
     * @param lpAmount The amount of LP token outputted
     * @param from The address of the msg sender
     * @param subPoolGroups The subpool groups including calculations and shares array
     */
    event AddedLiqShares(uint256 lpAmount, address from, DataTypes.SubPoolGroup[] subPoolGroups);

    /**
     * @dev Emitted when removing liquidity by a liqduity provider
     * @param stableOut The amount of stablecoin outputted
     * @param lpAmount The amount of LP token inputted
     * @param from The address of the msg sender
     * @param queued If transaction is queued = true
     */
    event RemovedLiqStable(uint256 stableOut, uint256 lpAmount, address from, bool queued);

    /**
     * @dev Emitted when removing liquidity by a liqduity provider
     * @param lpAmount The amount of LP token inputted
     * @param from The address of the msg sender
     * @param queued If transaction is queued = true
     * @param subPoolGroups The subpool groups including calculations and shares array
     */
    event RemovedLiqShares(uint256 lpAmount, address from, bool queued, DataTypes.SubPoolGroup[] subPoolGroups);

    /**
     * @dev Emitted when swap of stable coins occures
     * @param stableIn The amount of stablecoin supplied
     * @param fees The fees collected
     * @param user The user address
     * @param subPoolGroups The subpool groups including calculations and shares array
     */
    event SwappedStable(uint256 stableIn, DataTypes.FeeReturn fees, address user, DataTypes.SubPoolGroup[] subPoolGroups);

    /**
     * @dev Emitted when swap of shares occures
     * @param stableOut The amount of stablecoin outputted
     * @param fees The fees collected
     * @param user The user address
     * @param subPoolGroups The subpool groups including calculations and shares array
     */
    event SwappedShares(uint256 stableOut, DataTypes.FeeReturn fees, address user, DataTypes.SubPoolGroup[] subPoolGroups);

    /**
     * @dev Emitted when withdrawals are processed after the cooldown period
     * @param user The user that processed the withdrawals
     * @param transactionsCount The number of transactions processed
     */
    event WithdrawalsProcessed(address user, uint256 transactionsCount);

    /**
     * @dev Function to distribute liquidity to all subpools according to their weight
     * @notice the last subpool gets the remainder, if any
     * @param amount The account to deduct the stables from
     * @param tvl The TVL of the pool
     * @param poolData The liquidity pool data structure
     * @param subPools The subpools array
     */
    function distributeLiquidityToAll(
        uint256 amount,
        uint256 tvl,
        DataTypes.PoolData storage poolData,
        DataTypes.AMMSubPool1155[] storage subPools
    ) public {
        require(subPools.length > 0, Errors.NO_SUB_POOL_AVAILABLE);
        uint256 remaining = amount;
        uint256 weighted = 0;
        //Iterate through the subpools and add liquidity in a weighted manner and the remainder goes to the last subpool
        for (uint256 i = 0; i < subPools.length; ++i) {
            if (subPools[i].status) {
                if (i == subPools.length - 1) {
                    subPools[i].reserve += remaining;
                } else {
                    if (tvl == 0) {
                        subPools[i].reserve += amount / subPools.length;
                        remaining -= amount / subPools.length;
                    } else {
                        weighted = (amount * Pool1155Logic.calculateTotal(subPools, i)) / tvl;
                        remaining -= weighted;
                        subPools[i].reserve += weighted;
                    }
                }
                Pool1155Logic.updatePriceIterative(subPools, poolData, i);
            }
        }
    }

    function depositInitial(
        address user,
        uint256 subPoolId,
        uint256 stableIn,
        DataTypes.Shares1155Params memory params,
        DataTypes.PoolData storage poolData,
        DataTypes.AMMSubPool1155[] storage subPools,
        mapping(uint256 => uint256) storage tokenDistribution
    ) external {
        require(Pool1155Logic.calculateTotal(subPools, subPoolId) == 0, "SUBPOOL_NOT_EMPTY");
        for (uint256 i = 0; i < params.tokenIds.length; ++i) {
            require(tokenDistribution[params.tokenIds[i]] == subPoolId, "NOT_SAME_SUBPOOL_DISTRIBUTION");
            subPools[subPoolId].shares[params.tokenIds[i]] += params.amounts[i];
            subPools[subPoolId].totalShares += params.amounts[i];
        }
        subPools[subPoolId].reserve += stableIn;
        Pool1155Logic.updatePriceIterative(subPools, poolData, subPoolId);
        emit DepositInitiated(user, subPoolId, stableIn, params, subPools[subPoolId].totalShares, subPools[subPoolId].F);
        IERC1155(poolData.tokens[0]).safeBatchTransferFrom(user, poolData.poolLPToken, params.tokenIds, params.amounts, "");
        IERC20(poolData.stable).safeTransferFrom(user, poolData.poolLPToken, stableIn);
        ILPToken(poolData.poolLPToken).mint(
            user,
            MathHelpers.convertToWad(Pool1155Logic.calculateTotal(subPools, subPoolId)) / subPools.getLPPrice(poolData.poolLPToken)
        );
    }

    /**
     * @dev Function to remove liquidity by stable coins
     * @param user The account to deduct the stables from
     * @param targetLP The amount of LPs required
     * @param maxStable the maximum stablecoins to transfer
     * @param poolData The liquidity pool data structure
     * @param subPools The subpools array
     */
    function addLiquidityStable(
        address user,
        uint256 targetLP,
        uint256 maxStable,
        DataTypes.PoolData storage poolData,
        DataTypes.AMMSubPool1155[] storage subPools
    ) external returns (uint256, uint256) {
        require(user != address(0), Errors.ADDRESS_IS_ZERO);
        require(IERC20(poolData.stable).allowance(user, address(this)) >= maxStable, Errors.NOT_ENOUGH_APPROVED);
        require(IERC20(poolData.stable).balanceOf(user) >= maxStable, Errors.NOT_ENOUGH_USER_BALANCE);
        DataTypes.LiqLocalVars memory vars;
        (vars.TVL, vars.LPPrice) = subPools.getTVLAndLPPrice(poolData.poolLPToken);
        require(poolData.liquidityLimit.poolTvlLimit >= vars.TVL + maxStable, Errors.TVL_LIMIT_REACHED);
        //if TVL > 0 and deposit > TVL * limitPercentage, then revert where deposit is (requiredLP + totalLPOwned) * price
        //for v1.1
        // require(
        //     vars.TVL == 0 ||
        //         ((MathHelpers.convertFromWad((targetLP + ILPToken(poolData.poolLPToken).getBalanceOf(user)) * vars.LPPrice)) <=
        //             MathHelpers.convertFromWadPercentage(vars.TVL * poolData.liquidityLimit.maxDepositPercentage)),
        //     Errors.DEPOSIT_LIMIT_REACHED
        // );
        if ((MathHelpers.convertFromWad(targetLP * vars.LPPrice)) > maxStable) {
            vars.LPAmount = MathHelpers.convertToWad(maxStable) / vars.LPPrice;
            vars.stable = maxStable;
        } else {
            vars.LPAmount = targetLP;
            vars.stable = MathHelpers.convertFromWad(targetLP * vars.LPPrice);
        }
        distributeLiquidityToAll(vars.stable, vars.TVL, poolData, subPools);

        emit AddedLiqStable(vars.stable, vars.LPAmount, user);
        IERC20(poolData.stable).safeTransferFrom(user, poolData.poolLPToken, vars.stable);
        ILPToken(poolData.poolLPToken).mint(user, vars.LPAmount);
        return (vars.stable, vars.LPAmount);
    }

    /**
     * @dev Function to add liquidity by shares while grouping by subpool
     * @param user The account to deduct stable from
     * @param targetLP The amount of LPs required
     * @param params The shares arrays (token ids, amounts)
     * @param poolData The data of the liquidity pool
     * @param subPools The subPools array
     * @param tokenDistribution The token distribution mapping
     */
    function addLiquidityShares(
        address user,
        uint256 targetLP,
        DataTypes.Shares1155Params memory params,
        DataTypes.PoolData storage poolData,
        DataTypes.AMMSubPool1155[] storage subPools,
        mapping(uint256 => uint256) storage tokenDistribution
    ) external returns (uint256) {
        require(user != address(0), Errors.ADDRESS_IS_ZERO);
        require(params.tokenIds.length == params.amounts.length, Errors.ARRAY_NOT_SAME_LENGTH);
        require(IERC1155(poolData.tokens[0]).isApprovedForAll(user, address(this)), Errors.NOT_ENOUGH_APPROVED);
        DataTypes.LiqLocalVars memory vars;
        (vars.TVL, vars.LPPrice) = subPools.getTVLAndLPPrice(poolData.poolLPToken);
        //for v1.1
        //if TVL > 0 and deposit > TVL * limitPercentage, then revert where deposit is (requiredLP + totalLPOwned) * price
        // require(
        //     vars.TVL == 0 ||
        //         ((MathHelpers.convertFromWad((targetLP + ILPToken(poolData.poolLPToken).getBalanceOf(user)) * vars.LPPrice)) <=
        //             MathHelpers.convertFromWadPercentage(vars.TVL * poolData.liquidityLimit.maxDepositPercentage)),
        //     Errors.DEPOSIT_LIMIT_REACHED
        // );
        require(
            poolData.liquidityLimit.poolTvlLimit >= vars.TVL + (MathHelpers.convertFromWad(targetLP * vars.LPPrice)),
            Errors.TVL_LIMIT_REACHED
        );

        vars.remainingLP = targetLP;
        (vars.subPoolGroups, vars.counter) = groupBySubpoolDynamic(params, subPools.length, tokenDistribution);
        for (vars.i; vars.i < vars.counter; ++vars.i) {
            vars.currentSubPool = vars.subPoolGroups[vars.i];
            vars.poolId = vars.currentSubPool.id;
            require(subPools[vars.poolId].status, Errors.SUBPOOL_DISABLED);
            require(
                subPools[vars.poolId].F >= poolData.iterativeLimit.minimumF,
                Errors.ADDING_SHARES_TEMPORARY_DISABLED_DUE_TO_LOW_CONDITIONS
            );
            vars.currentSubPool.sharesCal = Pool1155Logic.CalculateShares(
                DataTypes.OperationType.sellShares,
                subPools,
                vars.poolId,
                poolData,
                vars.currentSubPool.total,
                false
            );
            vars.maxLPPerShares = (MathHelpers.convertToWad(vars.currentSubPool.sharesCal.value) / vars.LPPrice);
            require(vars.maxLPPerShares <= vars.remainingLP, Errors.SHARES_VALUE_EXCEEDS_TARGET);
            vars.remainingLP -= vars.maxLPPerShares;
            subPools[vars.poolId].totalShares += vars.currentSubPool.total;
            subPools[vars.poolId].F = vars.currentSubPool.sharesCal.F;

            for (vars.y = 0; vars.y < vars.currentSubPool.counter; ++vars.y) {
                vars.currentShare = vars.currentSubPool.shares[vars.y];
                subPools[vars.poolId].shares[vars.currentShare.tokenId] += vars.currentShare.amount;
                //Transfer the share tokens
                //We cant transfer batch outside the loop since the array of token ids and amounts have a counter after grouping
                //To generate proper token ids and amounts arrays for transfer batch, the groupBySubpoolDynamic will be redesigned and cost more gas
                //Even if grouped and the transfer is outside the current for loop, there is still another for loop due to economy of scale approach
                IERC1155(poolData.tokens[0]).safeTransferFrom(
                    user,
                    poolData.poolLPToken,
                    vars.currentShare.tokenId,
                    vars.currentShare.amount,
                    ""
                );
            }
            if (vars.remainingLP == 0) {
                break;
            }
        }
        vars.LPAmount = targetLP - vars.remainingLP;
        emit AddedLiqShares(vars.LPAmount, user, vars.subPoolGroups);
        ILPToken(poolData.poolLPToken).mint(user, vars.LPAmount);
        return (vars.LPAmount);
    }

    /**
     * @dev Function to remove liquidity by stable coins
     * @param user The account to remove LP from
     * @param yieldReserve The current reserve deposited in yield generators
     * @param targetLP The amount of LPs to be burned
     * @param minStable The minimum stable tokens to receive
     * @param poolData The liquidity pool data structure
     * @param subPools The subpools array
     * @param queuedWithdrawals The queued withdrawals
     */
    function removeLiquidityStable(
        address user,
        uint256 yieldReserve,
        uint256 targetLP,
        uint256 minStable,
        DataTypes.PoolData storage poolData,
        DataTypes.AMMSubPool1155[] storage subPools,
        DataTypes.Queued1155Withdrawals storage queuedWithdrawals
    ) external returns (uint256, uint256) {
        require(user != address(0), Errors.ADDRESS_IS_ZERO);
        require(ILPToken(poolData.poolLPToken).getBalanceOf(user) >= targetLP, Errors.NOT_ENOUGH_USER_BALANCE);
        require(subPools.length > 0, Errors.NO_SUB_POOL_AVAILABLE);
        DataTypes.LiqLocalVars memory vars;
        (vars.TVL, vars.LPPrice) = subPools.getTVLAndLPPrice(poolData.poolLPToken);
        //Check how much stablecoins remaining in the pool excluding yield investment
        vars.stableRemaining = IERC20(poolData.stable).balanceOf(poolData.poolLPToken) - yieldReserve;
        //Calculate maximum LP Tokens to remove
        vars.remainingLP = targetLP.min(MathHelpers.convertToWad(vars.stableRemaining) / vars.LPPrice);
        for (vars.i; vars.i < subPools.length; ++vars.i) {
            if (subPools[vars.i].status) {
                vars.weighted = vars.remainingLP.min((targetLP * Pool1155Logic.calculateTotal(subPools, vars.i)) / vars.TVL);
                vars.stable = MathHelpers.convertFromWad(vars.weighted * vars.LPPrice);
                vars.stable = subPools[vars.i].reserve.min(vars.stable);
                subPools[vars.i].reserve -= vars.stable;
                Pool1155Logic.updatePriceIterative(subPools, poolData, vars.i);
                vars.stableTotal += vars.stable;
                vars.remainingLP -= vars.weighted;
            }
        }
        vars.LPAmount = targetLP - vars.remainingLP;
        require(vars.stableTotal >= minStable, Errors.LP_VALUE_BELOW_TARGET);
        emit RemovedLiqStable(vars.stableTotal, vars.LPAmount, user, poolData.liquidityLimit.cooldown > 0 ? true : false);
        //If there is a cooldown, then store the stable in an array in the user data to be released later
        if (poolData.liquidityLimit.cooldown == 0) {
            ILPToken(poolData.poolLPToken).setApproval20(poolData.stable, vars.stableTotal);
            IERC20(poolData.stable).safeTransferFrom(poolData.poolLPToken, user, vars.stableTotal);
        } else {
            DataTypes.Withdraw1155Data storage current = queuedWithdrawals.withdrawals[queuedWithdrawals.nextId];
            current.to = user;
            //Using block.timestamp is safer than block number
            //See: https://ethereum.stackexchange.com/questions/11060/what-is-block-timestamp/11072#11072
            current.unlockTimestamp = block.timestamp + poolData.liquidityLimit.cooldown;
            current.amount = vars.stableTotal;
            ++queuedWithdrawals.nextId;
        }
        ILPToken(poolData.poolLPToken).burn(user, vars.LPAmount);
        return (vars.stableTotal, vars.LPAmount);
    }

    /**
     * @dev Function to remove liquidity by shares
     * @param user The account to burn from
     * @param targetLP The amount of LPs to be burned
     * @param params The shares arrays (token ids, amounts)
     * @param poolData The data of the liquidity pool
     * @param subPools The subPools array
     * @param queuedWithdrawals The queued withdrawals
     * @param tokenDistribution The token distribution mapping
     */
    function removeLiquidityShares(
        address user,
        uint256 targetLP,
        DataTypes.Shares1155Params memory params,
        DataTypes.PoolData storage poolData,
        DataTypes.AMMSubPool1155[] storage subPools,
        DataTypes.Queued1155Withdrawals storage queuedWithdrawals,
        //mapping(uint256 => uint256) storage subPoolGroupsPointer,
        mapping(uint256 => uint256) storage tokenDistribution
    ) external returns (uint256) {
        require(user != address(0), Errors.ADDRESS_IS_ZERO);
        require(params.tokenIds.length == params.amounts.length, Errors.ARRAY_NOT_SAME_LENGTH);
        require(ILPToken(poolData.poolLPToken).getBalanceOf(user) >= targetLP, Errors.NOT_ENOUGH_USER_BALANCE);
        DataTypes.LiqLocalVars memory vars;
        //Get LP Price
        vars.LPPrice = subPools.getLPPrice(poolData.poolLPToken);
        vars.remainingLP = targetLP;
        DataTypes.AMMShare1155[] storage queuedShares = queuedWithdrawals.withdrawals[queuedWithdrawals.nextId].shares;
        //Get the grouped token ids by subpool
        (vars.subPoolGroups, vars.counter) = groupBySubpoolDynamic(params, subPools.length, tokenDistribution);
        //iterate the subpool groups
        for (vars.i; vars.i < vars.counter; ++vars.i) {
            vars.currentSubPool = vars.subPoolGroups[vars.i];
            vars.poolId = vars.currentSubPool.id;
            require(subPools[vars.poolId].status, Errors.SUBPOOL_DISABLED);
            //Calculate the value of the shares inside this group
            vars.currentSubPool.sharesCal = Pool1155Logic.CalculateShares(
                DataTypes.OperationType.buyShares,
                subPools,
                vars.poolId,
                poolData,
                vars.currentSubPool.total,
                false
            );
            vars.maxLPPerShares = MathHelpers.convertToWad(vars.currentSubPool.sharesCal.value) / vars.LPPrice;
            require(vars.maxLPPerShares <= vars.remainingLP, Errors.SHARES_VALUE_EXCEEDS_TARGET);
            vars.remainingLP -= vars.maxLPPerShares;
            //Update the subpool
            subPools[vars.poolId].totalShares -= params.amounts[vars.i];
            subPools[vars.poolId].F = vars.currentSubPool.sharesCal.F;

            for (vars.y = 0; vars.y < vars.currentSubPool.counter; ++vars.y) {
                vars.currentShare = vars.currentSubPool.shares[vars.y];
                require(
                    subPools[vars.poolId].shares[vars.currentShare.tokenId] >= vars.currentShare.amount,
                    Errors.NOT_ENOUGH_SUBPOOL_SHARES
                );
                subPools[vars.poolId].shares[vars.currentShare.tokenId] -= vars.currentShare.amount;
                //Transfer the share tokens
                //We cant transfer batch outside the loop since the array of token ids and amounts have a counter after grouping
                //To generate proper token ids and amounts arrays for transfer batch, the groupBySubpoolDynamic will be redesigned and cost more gas
                //Even if grouped and the transfer is outside the current for loop, there is still another for loop due to economy of scale approach
                IERC1155(poolData.tokens[0]).safeTransferFrom(
                    poolData.poolLPToken,
                    user,
                    vars.currentShare.tokenId,
                    vars.currentShare.amount,
                    ""
                );
                //If there is a cooldown, then store the shares in an array in the user data to be released later
                if (poolData.liquidityLimit.cooldown > 0) {
                    queuedShares.push(DataTypes.AMMShare1155(params.tokenIds[vars.i], params.amounts[vars.i]));
                }
            }
        }
        //If cooldown is enabled, queue the withdrawal
        if (poolData.liquidityLimit.cooldown > 0) {
            queuedWithdrawals.withdrawals[queuedWithdrawals.nextId].to = user;
            //Using block.timestamp is safer than block number
            //See: https://ethereum.stackexchange.com/questions/11060/what-is-block-timestamp/11072#11072
            queuedWithdrawals.withdrawals[queuedWithdrawals.nextId].unlockTimestamp = block.timestamp + poolData.liquidityLimit.cooldown;
            queuedWithdrawals.withdrawals[queuedWithdrawals.nextId].shares = queuedShares;
            ++queuedWithdrawals.nextId;
        }
        vars.LPAmount = targetLP - vars.remainingLP;
        emit RemovedLiqShares(vars.LPAmount, user, poolData.liquidityLimit.cooldown > 0 ? true : false, vars.subPoolGroups);
        //Burn the LP Token
        ILPToken(poolData.poolLPToken).burn(user, vars.LPAmount);
        return (vars.LPAmount);
    }

    /**
     * @dev Function to process queued withdraw transactions upto limit and return number of transactions processed
     * @notice make it update F if needed for future
     * @param limit The number of transactions to process in queue
     * @param poolData The liquidity pool data structure
     * @param queuedWithdrawals The queued withdrawals
     * @return transactions number of transactions processed. 0 = no transactions in queue
     */
    function processWithdrawals(
        uint256 limit,
        DataTypes.PoolData storage poolData,
        DataTypes.Queued1155Withdrawals storage queuedWithdrawals
    ) external returns (uint256 transactions) {
        for (uint256 i; i < limit; ++i) {
            DataTypes.Withdraw1155Data storage current = queuedWithdrawals.withdrawals[queuedWithdrawals.headId];
            //Using block.timestamp is safer than block number
            //See: https://ethereum.stackexchange.com/questions/11060/what-is-block-timestamp/11072#11072
            if (current.unlockTimestamp < block.timestamp) break;
            if (current.amount > 0) {
                ILPToken(poolData.poolLPToken).setApproval20(poolData.stable, current.amount);
                IERC20(poolData.stable).safeTransferFrom(poolData.poolLPToken, current.to, current.amount);
            }
            for (uint256 j = 0; j < current.shares.length; ++j) {
                IERC1155(poolData.tokens[0]).safeTransferFrom(
                    poolData.poolLPToken,
                    current.to,
                    current.shares[j].tokenId,
                    current.shares[j].amount,
                    ""
                );
            }
            ++transactions;
            ++queuedWithdrawals.headId;
        }
        if (queuedWithdrawals.nextId == queuedWithdrawals.headId) {
            queuedWithdrawals.nextId = 0;
            queuedWithdrawals.headId = 0;
        }
        emit WithdrawalsProcessed(msg.sender, transactions);
    }

    /**
     * @dev Function that returns an array of structures that represent that subpools found that has an array of shares in those subpools and the counter represents the length of the outer and inner arrays
     * @param  params The shares arrays (token ids, amounts) to group
     * @param length the subpools length
     * @param tokenDistribution the token distribution of the liquidity pool
     * @return subPoolGroups array of DataTypes.SubPoolGroup output
     * @return counter The counter of array elements used
     */
    function groupBySubpoolDynamic(
        DataTypes.Shares1155Params memory params,
        uint256 length,
        mapping(uint256 => uint256) storage tokenDistribution
    ) public view returns (DataTypes.SubPoolGroup[] memory subPoolGroups, uint256 counter) {
        subPoolGroups = new DataTypes.SubPoolGroup[](length);
        counter = 0;
        DataTypes.LocalGroupVars memory vars;
        //Get the token ids
        if (params.tokenIds.length == 1) {
            counter = 1;
            subPoolGroups = new DataTypes.SubPoolGroup[](1);
            subPoolGroups[0] = DataTypes.SubPoolGroup(
                tokenDistribution[params.tokenIds[0]],
                1,
                params.amounts[0],
                new DataTypes.AMMShare1155[](1),
                vars.cal
            );
            subPoolGroups[0].shares[0] = DataTypes.AMMShare1155(params.tokenIds[0], params.amounts[0]);
        } else {
            //First we create an array of same length of the params and fill it with the token ids, subpool ids and amounts
            vars.paramGroups = new DataTypes.ParamGroup[](params.tokenIds.length);
            for (vars.i; vars.i < params.tokenIds.length; ++vars.i) {
                vars.paramGroups[vars.i].subPoolId = tokenDistribution[params.tokenIds[vars.i]];
                vars.paramGroups[vars.i].amount = params.amounts[vars.i];
                vars.paramGroups[vars.i].tokenId = params.tokenIds[vars.i];
            }
            //Then we sort the new array using the insertion method
            for (vars.i = 1; vars.i < vars.paramGroups.length; ++vars.i) {
                for (uint j = 0; j < vars.i; ++j)
                    if (vars.paramGroups[vars.i].subPoolId < vars.paramGroups[j].subPoolId) {
                        DataTypes.ParamGroup memory x = vars.paramGroups[vars.i];
                        vars.paramGroups[vars.i] = vars.paramGroups[j];
                        vars.paramGroups[j] = x;
                    }
            }
            //The we iterate last time through the array and construct the subpool group
            for (vars.i = 0; vars.i < vars.paramGroups.length; ++vars.i) {
                if (vars.i == 0 || vars.paramGroups[vars.i].subPoolId != vars.paramGroups[vars.i - 1].subPoolId) {
                    subPoolGroups[counter] = DataTypes.SubPoolGroup(
                        vars.paramGroups[vars.i].subPoolId,
                        0,
                        0,
                        new DataTypes.AMMShare1155[](vars.paramGroups.length),
                        vars.cal
                    );
                    ++counter;
                }
                vars.index = counter - 1;
                subPoolGroups[vars.index].shares[subPoolGroups[vars.index].counter] = DataTypes.AMMShare1155(
                    vars.paramGroups[vars.i].tokenId,
                    vars.paramGroups[vars.i].amount
                );
                subPoolGroups[vars.index].total += vars.paramGroups[vars.i].amount;
                ++subPoolGroups[vars.index].counter;
            }
        }
    }

    /** @dev Get full quotation
     * @param quoteParams the quote params containing the buy/sell flag and the use fee flag
     * @param params The shares arrays (token ids, amounts)
     * @param poolData The liquidity pool data
     * @param subPools the subpools array of the liquidity pool
     * @param tokenDistribution the token distribution of the liquidity pool
     */
    function getQuote(
        DataTypes.QuoteParams calldata quoteParams,
        DataTypes.Shares1155Params calldata params,
        DataTypes.PoolData storage poolData,
        DataTypes.AMMSubPool1155[] storage subPools,
        mapping(uint256 => uint256) storage tokenDistribution
    ) external view returns (DataTypes.Quotation memory quotation) {
        require(params.tokenIds.length == params.amounts.length, Errors.ARRAY_NOT_SAME_LENGTH);
        DataTypes.LocalQuoteVars memory vars;
        quotation.shares = new DataTypes.SharePrice[](params.tokenIds.length);
        //Get the grouped token ids by subpool
        (vars.subPoolGroups, vars.counter) = groupBySubpoolDynamic(params, subPools.length, tokenDistribution);
        for (vars.i; vars.i < vars.counter; ++vars.i) {
            vars.currentSubPool = vars.subPoolGroups[vars.i];
            vars.poolId = vars.currentSubPool.id;
            require(subPools[vars.poolId].status, Errors.SUBPOOL_DISABLED);
            //Calculate the value of the shares from its subpool
            vars.currentSubPool.sharesCal = Pool1155Logic.CalculateShares(
                quoteParams.buy ? DataTypes.OperationType.buyShares : DataTypes.OperationType.sellShares,
                subPools,
                vars.poolId,
                poolData,
                vars.currentSubPool.total,
                quoteParams.useFee
            );
            for (vars.y = 0; vars.y < vars.currentSubPool.counter; ++vars.y) {
                vars.currentShare = vars.currentSubPool.shares[vars.y];
                require(
                    subPools[vars.poolId].shares[vars.currentShare.tokenId] >= vars.currentShare.amount || !quoteParams.buy,
                    Errors.NOT_ENOUGH_SUBPOOL_SHARES
                );
                quotation.shares[vars.counterShares].value = vars.currentShare.amount * vars.currentSubPool.sharesCal.swapPV;
                quotation.shares[vars.counterShares].id = vars.currentShare.tokenId;
                quotation.shares[vars.counterShares].fees = Pool1155Logic.multiplyFees(
                    vars.subPoolGroups[vars.i].sharesCal.fees,
                    vars.currentShare.amount,
                    vars.currentSubPool.total
                );
                ++vars.counterShares;
            }
            quotation.fees = Pool1155Logic.addFees(quotation.fees, vars.subPoolGroups[vars.i].sharesCal.fees);
            require(
                subPools[vars.poolId].reserve >= vars.subPoolGroups[vars.i].sharesCal.value || quoteParams.buy,
                Errors.NOT_ENOUGH_SUBPOOL_RESERVE
            );
            quotation.total += vars.subPoolGroups[vars.i].sharesCal.value;
        }
    }

    /** @dev Experimental Function to the swap shares to stablecoins using grouping by subpools
     * @notice subPoolGroupsPointer should be cleared by making it "1" after each iteration of the grouping
     * @param user The user address to transfer the shares from
     * @param  minStable The minimum stablecoins to receive
     * @param  yieldReserve The current reserve in yield contracts
     * @param  params The shares arrays to deduct (token ids, amounts)
     * @param poolData The pool data including fee configuration
     * @param subPools the subpools array of the liquidity pool
     * @param tokenDistribution the token distribution of the liquidity pool
     */
    function swapShares(
        address user,
        uint256 minStable,
        uint256 yieldReserve,
        DataTypes.Shares1155Params memory params,
        DataTypes.PoolData storage poolData,
        DataTypes.AMMSubPool1155[] storage subPools,
        mapping(uint256 => uint256) storage tokenDistribution
    ) external {
        require(params.tokenIds.length == params.amounts.length, Errors.ARRAY_NOT_SAME_LENGTH);

        DataTypes.SwapLocalVars memory vars;
        (vars.subPoolGroups, vars.counter) = groupBySubpoolDynamic(params, subPools.length, tokenDistribution);
        //Check how much stablecoins remaining in the pool excluding yield investment
        require(IERC20(poolData.stable).balanceOf(poolData.poolLPToken) - yieldReserve >= minStable, Errors.NOT_ENOUGH_POOL_RESERVE);
        //Get the grouped token ids by subpool
        for (vars.i; vars.i < vars.counter; ++vars.i) {
            vars.currentSubPool = vars.subPoolGroups[vars.i];
            vars.poolId = vars.currentSubPool.id;
            require(
                subPools[vars.poolId].F >= poolData.iterativeLimit.minimumF,
                Errors.SWAPPING_SHARES_TEMPORARY_DISABLED_DUE_TO_LOW_CONDITIONS
            );
            require(subPools[vars.poolId].status, Errors.SUBPOOL_DISABLED);
            //Calculate the value of the shares inside this group
            vars.currentSubPool.sharesCal = Pool1155Logic.CalculateShares(
                DataTypes.OperationType.sellShares,
                subPools,
                vars.poolId,
                poolData,
                vars.currentSubPool.total,
                true
            );
            vars.stable =
                vars.currentSubPool.sharesCal.value -
                vars.currentSubPool.sharesCal.fees.royalties -
                vars.currentSubPool.sharesCal.fees.protocolFee;
            //Skip this subpool if there isn't enough
            //The pricing depends on all the shares together, otherwise we need to break them and re-iterate (future feature)
            require(vars.currentSubPool.sharesCal.value <= subPools[vars.poolId].reserve, Errors.NOT_ENOUGH_SUBPOOL_RESERVE);

            vars.stableOut += vars.stable;
            //add the total fees for emitting the event
            vars.fees = Pool1155Logic.addFees(vars.fees, vars.currentSubPool.sharesCal.fees);
            //Update the reserve of stable and shares and F
            subPools[vars.poolId].reserve -= (vars.currentSubPool.sharesCal.value);
            subPools[vars.poolId].totalShares += vars.currentSubPool.total;
            subPools[vars.poolId].F = vars.currentSubPool.sharesCal.F;
            //Iterate through the shares inside the Group
            for (vars.y = 0; vars.y < vars.currentSubPool.counter; ++vars.y) {
                vars.currentShare = vars.currentSubPool.shares[vars.y];
                subPools[vars.poolId].shares[vars.currentShare.tokenId] += vars.currentShare.amount;
                //Transfer the tokens
                //We cant transfer batch outside the loop since the array of token ids and amounts have a counter after grouping
                //To generate proper token ids and amounts arrays for transfer batch, the groupBySubpoolDynamic will be redesigned and cost more gas
                //Even if grouped and the transfer is outside the current for loop, there is still another for loop due to economy of scale approach
                IERC1155(poolData.tokens[0]).safeTransferFrom(
                    user,
                    poolData.poolLPToken,
                    vars.currentShare.tokenId,
                    vars.currentShare.amount,
                    ""
                );
            }
        }
        require(vars.stableOut >= minStable, Errors.SHARES_VALUE_BELOW_TARGET);
        if (vars.stableOut > 0) {
            emit SwappedShares(vars.stableOut, vars.fees, user, vars.subPoolGroups);
            //Add to the balances of the protocol wallet and royalties address
            poolData.fee.protocolBalance += vars.fees.protocolFee;
            poolData.fee.royaltiesBalance += vars.fees.royalties;
            //Transfer the total stable to the user
            ILPToken(poolData.poolLPToken).setApproval20(poolData.stable, vars.stableOut);
            IERC20(poolData.stable).safeTransferFrom(poolData.poolLPToken, user, vars.stableOut);
        }
    }

    /** @dev Experimental Function to the swap stablecoins to shares using grouping by subpools
     * @param user The user address to deduct stablecoins
     * @param maxStable the maximum stablecoins to deduct
     * @param  params The shares arrays (token ids, amounts)
     * @param poolData The pool data including fee configuration
     * @param subPools the subpools array of the liquidity pool
     * @param tokenDistribution the token distribution of the liquidity pool
     */
    function swapStable(
        address user,
        uint256 maxStable,
        DataTypes.Shares1155Params memory params,
        DataTypes.PoolData storage poolData,
        DataTypes.AMMSubPool1155[] storage subPools,
        mapping(uint256 => uint256) storage tokenDistribution
    ) external {
        require(params.tokenIds.length == params.amounts.length, Errors.ARRAY_NOT_SAME_LENGTH);
        require(IERC20(poolData.stable).allowance(user, address(this)) >= maxStable, Errors.NOT_ENOUGH_APPROVED);
        require(IERC20(poolData.stable).balanceOf(user) >= maxStable, Errors.NOT_ENOUGH_USER_BALANCE);
        DataTypes.SwapLocalVars memory vars;
        vars.remaining = maxStable;
        //Get the grouped token ids by subpool
        (vars.subPoolGroups, vars.counter) = groupBySubpoolDynamic(params, subPools.length, tokenDistribution);
        //iterate the subpool groups
        for (vars.i; vars.i < vars.counter; ++vars.i) {
            vars.currentSubPool = vars.subPoolGroups[vars.i];
            vars.poolId = vars.currentSubPool.id;
            require(subPools[vars.poolId].status, Errors.SUBPOOL_DISABLED);
            //Calculate the value of the shares inside this group
            //This requires that the total shares in the subpool >= amount requested or it reverts
            vars.currentSubPool.sharesCal = Pool1155Logic.CalculateShares(
                DataTypes.OperationType.buyShares,
                subPools,
                vars.poolId,
                poolData,
                vars.currentSubPool.total,
                true
            );
            //If the value of the shares is higher than the remaining stablecoins to consume, continue the for.
            // Otherwise, we would need to recalculate using the remaining stable
            // It is better to assume that the user approved more than the shares value
            //if (vars.currentSubPool.sharesCal.value + vars.currentSubPool.sharesCal.fees.totalFee > vars.remaining) continue;
            require(
                vars.currentSubPool.sharesCal.value +
                    vars.currentSubPool.sharesCal.fees.royalties +
                    vars.currentSubPool.sharesCal.fees.protocolFee <=
                    vars.remaining,
                Errors.SHARES_VALUE_EXCEEDS_TARGET
            );

            vars.remaining -= (vars.currentSubPool.sharesCal.value +
                vars.currentSubPool.sharesCal.fees.royalties +
                vars.currentSubPool.sharesCal.fees.protocolFee);
            //increment the total fees for emitting the event
            vars.fees = Pool1155Logic.addFees(vars.fees, vars.currentSubPool.sharesCal.fees);
            //Update the reserve of stable and shares and F
            subPools[vars.poolId].reserve += vars.currentSubPool.sharesCal.value;
            subPools[vars.poolId].totalShares -= vars.currentSubPool.total;
            subPools[vars.poolId].F = vars.currentSubPool.sharesCal.F;
            //Iterate through all the shares to update their new amounts in the subpool
            for (vars.y = 0; vars.y < vars.currentSubPool.counter; ++vars.y) {
                vars.currentShare = vars.currentSubPool.shares[vars.y];
                require(
                    subPools[vars.poolId].shares[vars.currentShare.tokenId] >= vars.currentShare.amount,
                    Errors.NOT_ENOUGH_SUBPOOL_SHARES
                );
                subPools[vars.poolId].shares[vars.currentShare.tokenId] -= vars.currentShare.amount;
                //Transfer the tokens
                //We cant transfer batch outside the loop since the array of token ids and amounts have a counter after grouping
                //To generate proper token ids and amounts arrays for transfer batch, the groupBySubpoolDynamic will be redesigned and cost more gas
                //Even if grouped and the transfer is outside the current for loop, there is still another for loop due to economy of scale approach
                IERC1155(poolData.tokens[0]).safeTransferFrom(
                    poolData.poolLPToken,
                    user,
                    vars.currentShare.tokenId,
                    vars.currentShare.amount,
                    ""
                );
            }
        }
        //Add to the balances of the protocol wallet and royalties address
        poolData.fee.protocolBalance += vars.fees.protocolFee;
        poolData.fee.royaltiesBalance += vars.fees.royalties;
        emit SwappedStable(maxStable - vars.remaining, vars.fees, user, vars.subPoolGroups);
        //Transfer the total stable from the user
        IERC20(poolData.stable).safeTransferFrom(user, poolData.poolLPToken, maxStable - vars.remaining);
    }
}