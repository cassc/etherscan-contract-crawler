// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Errors} from "../libraries/Errors.sol";
import {ILPToken} from "../interfaces/ILPToken.sol";
import {LPToken} from "../amm/LPToken.sol";
import {MathHelpers} from "../libraries/MathHelpers.sol";
import {IPoolFactory1155} from "../interfaces/IPoolFactory1155.sol";
import {IAccessManager} from "../interfaces/IAccessManager.sol";
import {IAddressesRegistry} from "../interfaces/IAddressesRegistry.sol";
import {IAccessNFT} from "../interfaces/IAccessNFT.sol";
import {IStablecoinYieldConnector} from "../interfaces/IStablecoinYieldConnector.sol";
import {IConnectorRouter} from "../interfaces/IConnectorRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title library for pool logic functions for the 1155 Pools with single collection
 * @author Souq.Finance
 * @notice Defines the pure functions used by the 1155 contracts of the Souq protocol
 * @notice License: https://souq-nft-amm-v1.s3.amazonaws.com/LICENSE.md
 */

library Pool1155Logic {
    using SafeERC20 for IERC20;
    using Math for uint256;

    /**
     * @dev Emitted when stablecoins in the pool are deposited to a yield generating protocol
     * @param admin The admin that executed the function
     * @param amount The amount of stablecoins
     * @param yieldGeneratorAddress The address of the yield generating protocol
     */
    event YieldDeposited(address admin, uint256 amount, address yieldGeneratorAddress);
    /**
     * @dev Emitted when stablecoins in the pool are deposited to a yield generating protocol. The AToken is 1:1 the stable amount
     * @param admin The admin that executed the function
     * @param amount The amount of stablecoins
     * @param yieldGeneratorAddress The address of the yield generating protocol
     */
    event YieldWithdrawn(address admin, uint256 amount, address yieldGeneratorAddress);
    /**
     * @dev Emitted when tokens different than the tokens used by the pool are rescued for receivers by the admin
     * @param admin The admin that executed the function
     * @param token The address of the token contract
     * @param amount The amount of tokens
     * @param receiver The address of the receiver
     */
    event Rescued(address admin, address token, uint256 amount, address receiver);

    /**
     * @dev Emitted when a new LP Token is deployed
     * @param LPAdress The address of the LP Token
     * @param poolAddress The address of the liquidity pool that deployed it
     * @param tokens the addresses of the ERC1155 tokens that the liquidity pool utilizes
     * @param symbol the symbol of the LP Token
     * @param name the name of the LP Token
     * @param decimals the decimals of the LP Token
     */
    event LPTokenDeployed(address LPAdress, address poolAddress, address[] tokens, string symbol, string name, uint8 decimals);
    /**
     * @dev Emitted when a new sub pool is added by the admin
     * @param admin The admin that executed the function
     * @param f the initial F of the new pool
     * @param v the initial V of the new pool
     * @param id the id of the new sub pool
     */
    event AddedSubPool(address admin, uint256 v, uint256 f, uint256 id);

    /**
     * @dev Emitted when the V is updated for several subPools
     * @param admin The admin that executed the function
     * @param poolIds the indecies of the subPools
     * @param vArray the array of the new v's for the subPools
     */
    event UpdatedV(address admin, uint256[] poolIds, uint256[] vArray);

    /**
     * @dev Emitted when shares of a token id range in a subpool are moved to a new sub pool
     * @param admin The admin that executed the function
     * @param startId the start index of the token ids of the shares
     * @param endId the end index of the token ids of the shares
     * @param newSubPoolId the index of the new sub pool to move the shares to
     */
    event MovedShares(address admin, uint256 startId, uint256 endId, uint256 newSubPoolId);

    /**
     * @dev Emitted when shares of a token id array are moved to a new sub pool
     * @param admin The admin that executed the function
     * @param newSubPoolId the index of the new sub pool to move the shares to
     * @param ids the array of token ids
     */
    event MovedSharesList(address admin, uint256 newSubPoolId, uint256[] ids);

    /**
     * @dev Emmitted when the status of specific subpools is modified
     * @param admin The admin that executed the function
     * @param subPoolIds The sub pool ids array
     * @param newStatus The new status, enabled=true or disabled=false
     */
    event ChangedSubpoolStatus(address admin, uint256[] subPoolIds, bool newStatus);

    /**
     * @dev Emitted when reserve is moved between subpools
     * @param admin The admin that executed the function
     * @param moverId the id of the subpool to move funds from
     * @param movedId the id of the subpool to move funds to
     * @param amount the amount of funds to move
     */
    event MovedReserve(address admin, uint256 moverId, uint256 movedId, uint256 amount);

    /**
     * @dev Emitted when the accumulated fee balances are withdrawn by the royalties and protocol wallet addresses
     * @param user The sender of the transaction
     * @param to the address to send the funds to
     * @param amount the amount being withdrawn
     * @param feeType: string - the type of fee being withdrawan (royalties/protocol)
     */
    event WithdrawnFees(address user, address to, uint256 amount, string feeType);

    /**
     * @dev Function to calculate the total value of a sub pool
     * @param subPools The sub pools array
     * @param subPoolId the sub pool id
     * @return uint256 The total value of a subpool
     */
    function calculateTotal(DataTypes.AMMSubPool1155[] storage subPools, uint256 subPoolId) public view returns (uint256) {
        return
            subPools[subPoolId].reserve +
            MathHelpers.convertFromWad(subPools[subPoolId].totalShares * subPools[subPoolId].V * subPools[subPoolId].F);
    }

    /**
     * @dev Function to get the total TVL of the liquidity pool from its subpools
     * @param subPools The subpools array
     * @return total The TVL
     */
    function getTVL(DataTypes.AMMSubPool1155[] storage subPools) public view returns (uint256 total) {
        for (uint256 i; i < subPools.length; ++i) {
            total += calculateTotal(subPools, i);
        }
    }

    /**
     * @dev Function to get the LP Token price by dividing the TVL over the total minted tokens
     * @param subPools The subpools array
     * @param poolLPToken The address of the LP Token
     * @return uint256 The LP Price
     */
    function getLPPrice(DataTypes.AMMSubPool1155[] storage subPools, address poolLPToken) external view returns (uint256) {
        uint256 total = ILPToken(poolLPToken).getTotal();
        uint256 tvl = getTVL(subPools);
        if (total == 0 || tvl == 0) {
            return MathHelpers.convertToWad(1);
        }
        return MathHelpers.convertToWad(tvl) / total;
    }

    /**
     * @dev Function to get the TVL and LP Token price together which saves gas if we need both variables
     * @param subPools The subpools array
     * @param poolLPToken The address of the LP Token
     * @return (uint256,uint256) The TVL and LP Price
     */
    function getTVLAndLPPrice(DataTypes.AMMSubPool1155[] storage subPools, address poolLPToken) external view returns (uint256, uint256) {
        uint256 total = ILPToken(poolLPToken).getTotal();
        uint256 tvl = getTVL(subPools);
        if (total == 0 || tvl == 0) {
            return (tvl, MathHelpers.convertToWad(1));
        }
        return (tvl, (MathHelpers.convertToWad(tvl) / total));
    }

    /**
     * @dev Function to get the actual fee value structure depending on swap direction
     * @param operation The direction of the swap
     * @param value value of the amount to compute the fees for
     * @param fee The fee configuration of the liquidity pool
     * @return feeReturn The return fee structure that has the ratios
     */
    function calculateFees(
        DataTypes.OperationType operation,
        uint256 value,
        DataTypes.PoolFee storage fee
    ) public view returns (DataTypes.FeeReturn memory feeReturn) {
        uint256 actualValue;
        if (operation == DataTypes.OperationType.buyShares) {
            actualValue = MathHelpers.convertFromWadPercentage(value * (MathHelpers.convertToWadPercentage(1) - fee.lpBuyFee));
            feeReturn.royalties = MathHelpers.convertFromWadPercentage(fee.royaltiesBuyFee * actualValue);
            feeReturn.lpFee = MathHelpers.convertFromWadPercentage(fee.lpBuyFee * value);
            feeReturn.protocolFee = MathHelpers.convertFromWadPercentage(fee.protocolBuyRatio * actualValue);
        } else if (operation == DataTypes.OperationType.sellShares) {
            actualValue = MathHelpers.convertToWadPercentage(value) / (MathHelpers.convertToWadPercentage(1) - fee.lpSellFee);
            feeReturn.royalties = MathHelpers.convertFromWadPercentage(fee.royaltiesSellFee * actualValue);
            feeReturn.lpFee = MathHelpers.convertFromWadPercentage(fee.lpSellFee * value);
            feeReturn.protocolFee = MathHelpers.convertFromWadPercentage(fee.protocolSellRatio * actualValue);
        }
        feeReturn.swapFee = feeReturn.lpFee + feeReturn.protocolFee;
        feeReturn.totalFee = feeReturn.royalties + feeReturn.swapFee;
    }

    /**
     * @dev Function to add two feeReturn structures and output 1
     * @param x the first feeReturn struct
     * @param y the second feeReturn struct
     * @return z The return data structure
     */
    function addFees(DataTypes.FeeReturn memory x, DataTypes.FeeReturn memory y) external pure returns (DataTypes.FeeReturn memory z) {
        //Add all the fees together
        z.totalFee = x.totalFee + y.totalFee;
        z.royalties = x.royalties + y.royalties;
        z.protocolFee = x.protocolFee + y.protocolFee;
        z.lpFee = x.lpFee + y.lpFee;
        z.swapFee = x.swapFee + y.swapFee;
    }

    /**
     * @dev Function to multiply a fee structure by a number and divide by a den
     * @param fee the original feeReturn struct
     * @param num the numerator
     * @param den The denominator
     * @return feeReturn The new fee structure
     */
    function multiplyFees(
        DataTypes.FeeReturn memory fee,
        uint256 num,
        uint256 den
    ) external pure returns (DataTypes.FeeReturn memory feeReturn) {
        feeReturn.totalFee = (fee.totalFee * num) / den;
        feeReturn.royalties = (fee.royalties * num) / den;
        feeReturn.protocolFee = (fee.protocolFee * num) / den;
        feeReturn.lpFee = (fee.lpFee * num) / den;
        feeReturn.swapFee = (fee.swapFee * num) / den;
    }

    /**
     * @dev Function to calculate the price of a share in a sub pool\
     * @param operation the operation direction
     * @param subPools The sub pools array
     * @param subPoolId the sub pool id
     * @param poolData the pool data
     * @return sharesReturn The return data structure
     */
    function CalculateShares(
        DataTypes.OperationType operation,
        DataTypes.AMMSubPool1155[] storage subPools,
        uint256 subPoolId,
        DataTypes.PoolData storage poolData,
        uint256 shares,
        bool useFee
    ) external view returns (DataTypes.SharesCalculationReturn memory sharesReturn) {
        require(
            subPools[subPoolId].totalShares >= shares || operation != DataTypes.OperationType.buyShares,
            Errors.NOT_ENOUGH_SUBPOOL_SHARES
        );
        //Iterative approach
        DataTypes.SharesCalculationVars memory vars;
        //Initial values
        vars.V = subPools[subPoolId].V;
        vars.PV_0 = MathHelpers.convertFromWad(vars.V * subPools[subPoolId].F);
        sharesReturn.PV = vars.PV_0;
        //Calculate steps
        vars.steps = shares / poolData.iterativeLimit.maxBulkStepSize;
        //At first the stable = reserve
        vars.stable = subPools[subPoolId].reserve;
        vars.shares = subPools[subPoolId].totalShares;
        //Iterating step sizes for enhanced results. If amount = 50, and stepsize is 15, then we iterate 4 times 15,15,15,5
        for (vars.stepIndex; vars.stepIndex < vars.steps + 1; ++vars.stepIndex) {
            vars.stepAmount = vars.stepIndex == vars.steps
                ? (shares - ((vars.stepIndex) * poolData.iterativeLimit.maxBulkStepSize))
                : poolData.iterativeLimit.maxBulkStepSize;
            if (vars.stepAmount == 0) break;
            //The value of the shares are priced first at last PV
            vars.value = vars.stepAmount * vars.PV_0;
            if (useFee) vars.fees = calculateFees(operation, vars.value, poolData.fee);
            //Iterate the calculations while keeping PV_0 and stable the same and using the new PV to calculate the average and reiterate
            for (vars.i = 0; vars.i < poolData.iterativeLimit.iterations; ++vars.i) {
                if (operation == DataTypes.OperationType.buyShares) {
                    //if buying shares, the pool receives stable plus the swap fee and gives out shares
                    vars.newCash = vars.stable + vars.value + (useFee ? vars.fees.lpFee : 0);
                    vars.den =
                        vars.newCash +
                        ((poolData.coefficientB * (vars.shares - vars.stepAmount) * sharesReturn.PV) / poolData.coefficientC);
                } else if (operation == DataTypes.OperationType.sellShares) {
                    require(vars.stable >= vars.value, Errors.NOT_ENOUGH_SUBPOOL_RESERVE);
                    //if selling shares, the pool receives shares and gives out stable - total fees from the reserve
                    vars.newCash = vars.stable - vars.value + (useFee ? vars.fees.lpFee : 0);
                    vars.den =
                        vars.newCash +
                        ((poolData.coefficientB * (vars.shares + vars.stepAmount) * sharesReturn.PV) / poolData.coefficientC);
                }
                //Calculate new PV and F
                sharesReturn.F = vars.den == 0 ? 0 : (poolData.coefficientA * vars.newCash) / vars.den;
                sharesReturn.PV = MathHelpers.convertFromWad(vars.V * sharesReturn.F);
                //Swap PV is the price used for the swapping in the newCash
                vars.swapPV = vars.stepAmount > 1 ? ((sharesReturn.PV + vars.PV_0) / 2) : vars.PV_0;
                vars.value = vars.stepAmount * vars.swapPV;
                if (useFee) vars.fees = calculateFees(operation, vars.value, poolData.fee);
            }
            //We add/subtract the shares to be used in the next stepsize iteration
            vars.shares = operation == DataTypes.OperationType.buyShares ? vars.shares - vars.stepAmount : vars.shares + vars.stepAmount;
            //At the end of iterations, the stable is now the last cash value
            vars.stable = vars.newCash;
            //The starting PV is now the last PV value
            vars.PV_0 = sharesReturn.PV;
            //Add the amounts to the return
            sharesReturn.amount += vars.stepAmount;
        }
        //Calculate the actual value to return
        sharesReturn.value = operation == DataTypes.OperationType.buyShares
            ? vars.stable - subPools[subPoolId].reserve
            : subPools[subPoolId].reserve - vars.stable;
        //Calculate the final fees
        if (useFee) sharesReturn.fees = calculateFees(operation, sharesReturn.value, poolData.fee);
        //Average the swap PV in the return
        sharesReturn.swapPV = sharesReturn.value / sharesReturn.amount;
    }

    /**
     * @dev Function to update the price iteratively in a subpool
     * @param subPools The sub pools array
     * @param poolData The pool data struct
     * @param subPoolId the sub pool id
     */
    function updatePriceIterative(
        DataTypes.AMMSubPool1155[] storage subPools,
        DataTypes.PoolData storage poolData,
        uint256 subPoolId
    ) public {
        //coef is converted to wad and we also need F to be converted to wad
        uint256 num = ((poolData.coefficientA * subPools[subPoolId].reserve));
        uint256 temp = poolData.coefficientB * subPools[subPoolId].totalShares * subPools[subPoolId].V;
        uint256 den = (subPools[subPoolId].reserve + (MathHelpers.convertFromWad(temp * subPools[subPoolId].F) / poolData.coefficientC));
        subPools[subPoolId].F = den == 0 ? 0 : num / den;
        //Iteration 0 is done, iterate through the rest
        if (poolData.iterativeLimit.iterations > 1) {
            for (uint256 i; i < poolData.iterativeLimit.iterations - 1; ++i) {
                den = (subPools[subPoolId].reserve + (MathHelpers.convertFromWad(subPools[subPoolId].F * temp) / poolData.coefficientC));
                subPools[subPoolId].F = den == 0 ? 0 : num / den;
            }
        }
    }

    /**
     * @dev Function to update the price in a subpool
     * @param subPools The sub pools array
     * @param coefficientA the coefficient A of the equation
     * @param coefficientB the coefficient B of the equation
     * @param coefficientC the coefficient C of the equation
     * @param subPoolId the sub pool id
     */
    function updatePrice(
        DataTypes.AMMSubPool1155[] storage subPools,
        uint256 coefficientA,
        uint256 coefficientB,
        uint256 coefficientC,
        uint256 subPoolId
    ) external {
        //coef is converted to wad and we also need F to be converted to wad
        uint256 num = ((coefficientA * subPools[subPoolId].reserve));
        uint256 den = (subPools[subPoolId].reserve +
            (MathHelpers.convertFromWad(coefficientB * subPools[subPoolId].totalShares * subPools[subPoolId].F * subPools[subPoolId].V) /
                coefficientC));
        subPools[subPoolId].F = den == 0 ? 0 : num / den;
    }

    /**
     * @dev Function to add a new sub pool
     * @param v The initial V value of the sub pool
     * @param f The initial F value of the sub pool
     * @param subPools The subpools array
     */
    function addSubPool(uint256 v, uint256 f, DataTypes.AMMSubPool1155[] storage subPools) external {
        DataTypes.AMMSubPool1155 storage newPool = subPools.push();
        newPool.reserve = 0;
        newPool.totalShares = 0;
        newPool.V = v;
        newPool.F = f;
        newPool.status = true;
        emit AddedSubPool(msg.sender, v, f, subPools.length - 1);
    }

    /**
     *@dev Function to update the V of the subpools
     *@param subPoolIds the array of subpool ids to update
     *@param vArray The array of V to update
     *@param subPools The subpools array
     */
    function updatePoolV(
        uint256[] calldata subPoolIds,
        uint256[] calldata vArray,
        DataTypes.AMMSubPool1155[] storage subPools,
        DataTypes.PoolData storage poolData
    ) external {
        require(subPoolIds.length == vArray.length, Errors.ARRAY_NOT_SAME_LENGTH);
        for (uint256 i; i < subPoolIds.length; ++i) {
            subPools[subPoolIds[i]].V = vArray[i];
            updatePriceIterative(subPools, poolData, subPoolIds[i]);
        }
        emit UpdatedV(msg.sender, subPoolIds, vArray);
    }

    /**
     *@dev Function to move shares between sub pools
     *@param startId The starting token id inside the subpool
     *@param endId The ending token id inside the subpool
     *@param newSubPoolId The id of the new subpool
     *@param subPools The subpools array
     *@param tokenDistribution The token distribution mapping of the liquidity pool
     */
    function moveShares(
        uint256 startId,
        uint256 endId,
        uint256 newSubPoolId,
        DataTypes.AMMSubPool1155[] storage subPools,
        DataTypes.PoolData storage poolData,
        mapping(uint256 => uint256) storage tokenDistribution
    ) external {
        DataTypes.MoveSharesVars memory vars;
        for (vars.i = startId; vars.i < endId + 1; ++vars.i) {
            vars.poolId = tokenDistribution[vars.i];
            if (subPools[newSubPoolId].shares[vars.i] > 0) {
                subPools[newSubPoolId].shares[vars.i] = subPools[vars.poolId].shares[vars.i];
                subPools[vars.poolId].shares[vars.i] = 0;
                updatePriceIterative(subPools, poolData, vars.poolId);
            }
            tokenDistribution[vars.i] = newSubPoolId;
        }
        emit MovedShares(msg.sender, startId, endId, newSubPoolId);
    }

    /**
     *@dev Function to move shares between sub pools
     *@param newSubPoolId The id of the new subpool
     *@param ids The token ids array to move
     *@param subPools The subpools array
     *@param tokenDistribution The token distribution mapping of the liquidity pool
     */
    function moveSharesList(
        uint256 newSubPoolId,
        uint256[] calldata ids,
        DataTypes.AMMSubPool1155[] storage subPools,
        DataTypes.PoolData storage poolData,
        mapping(uint256 => uint256) storage tokenDistribution
    ) external {
        DataTypes.MoveSharesVars memory vars;
        for (vars.i; vars.i < ids.length; ++vars.i) {
            vars.poolId = tokenDistribution[ids[vars.i]];
            if (subPools[newSubPoolId].shares[ids[vars.i]] > 0) {
                subPools[newSubPoolId].shares[ids[vars.i]] = subPools[vars.poolId].shares[ids[vars.i]];
                subPools[vars.poolId].shares[ids[vars.i]] = 0;
                updatePriceIterative(subPools, poolData, vars.poolId);
            }
            tokenDistribution[ids[vars.i]] = newSubPoolId;
        }
        emit MovedSharesList(msg.sender, newSubPoolId, ids);
    }

    /**
     * @dev Function to move enable or disable subpools by ids
     * @param subPoolIds The sub pool ids array
     * @param newStatus The new status, enabled=true or disabled=false
     * @param subPools The subpools array
     */
    function changeSubPoolStatus(uint256[] memory subPoolIds, bool newStatus, DataTypes.AMMSubPool1155[] storage subPools) external {
        for (uint256 i; i < subPoolIds.length; ++i) {
            subPools[subPoolIds[i]].status = newStatus;
        }
        emit ChangedSubpoolStatus(msg.sender, subPoolIds, newStatus);
    }

    /**
     * @dev Function to move reserves between subpools
     * @param moverId The sub pool that will move the funds from
     * @param movedId The id of the sub pool that will move the funds to
     * @param amount The amount to move
     * @param subPools The subpools array
     */
    function moveReserve(
        uint256 moverId,
        uint256 movedId,
        uint256 amount,
        DataTypes.AMMSubPool1155[] storage subPools,
        DataTypes.PoolData storage poolData
    ) external {
        require(subPools[moverId].reserve >= amount, Errors.NOT_ENOUGH_SUBPOOL_RESERVE);
        require(subPools.length > moverId && subPools.length > movedId, Errors.INVALID_SUBPOOL_ID);
        subPools[moverId].reserve -= amount;
        updatePriceIterative(subPools, poolData, moverId);
        subPools[movedId].reserve += amount;
        updatePriceIterative(subPools, poolData, movedId);
        emit MovedReserve(msg.sender, moverId, movedId, amount);
    }

    /**
     * @dev Function that returns the subpool ids of the given token ids
     * @param tokenIds The address of the pool
     * @param tokenDistribution The registry address
     * @return subPools array of the subpool ids
     */
    function getSubPools(
        uint256[] memory tokenIds,
        mapping(uint256 => uint256) storage tokenDistribution
    ) external view returns (uint256[] memory subPools) {
        subPools = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            subPools[i] = tokenDistribution[tokenIds[i]];
        }
    }

    /**
     * @dev Function that returns the subpool ids of the given sequencial token ids
     * @param startTokenId The start id of the token ids
     * @param endTokenId The end id of the token ids
     * @param tokenDistribution The registry address
     * @return subPools The array of the subpool ids
     */
    function getSubPoolsSeq(
        uint256 startTokenId,
        uint256 endTokenId,
        mapping(uint256 => uint256) storage tokenDistribution
    ) external view returns (uint256[] memory subPools) {
        require(startTokenId <= endTokenId, "END_ID_LESS_THAN_START");
        subPools = new uint256[](endTokenId - startTokenId + 1);
        for (uint256 i = startTokenId; i < endTokenId + 1; ++i) {
            subPools[i] = tokenDistribution[i];
        }
    }

    /**
     * @dev Function that deploys the LP Token of the pool
     * @param poolAddress The address of the pool
     * @param registry The registry address
     * @param tokens The collection tokens to be used by the pool
     * @param symbol The symbol of the LP Token
     * @param name The name of the LP Token
     * @param decimals The decimals of the LP Token
     * @return address of the LP Token
     */
    function deployLPToken(
        address poolAddress,
        address registry,
        address[] memory tokens,
        string memory symbol,
        string memory name,
        uint8 decimals
    ) external returns (address) {
        ILPToken poolLPToken = new LPToken(poolAddress, registry, tokens, symbol, name, decimals);
        emit LPTokenDeployed(address(poolLPToken), poolAddress, tokens, symbol, name, decimals);
        return address(poolLPToken);
    }

    /**
     * @dev Function to rescue and send ERC20 tokens (different than the tokens used by the pool) to a receiver called by the admin
     * @param token The address of the token contract
     * @param amount The amount of tokens
     * @param receiver The address of the receiver
     * @param stableToken The address of the stablecoin to rescue
     * @param poolLPToken The address of the pool LP Token
     */
    function RescueTokens(address token, uint256 amount, address receiver, address stableToken, address poolLPToken) external {
        require(token != stableToken, Errors.CANNOT_RESCUE_POOL_TOKEN);
        emit Rescued(msg.sender, token, amount, receiver);
        ILPToken(poolLPToken).RescueTokens(token, amount, receiver);
    }

    /**
     * @dev Function to deposit stablecoins from the pool to a yield generating protocol and getting synthetic tokens
     * @param amount The amount of stablecoins
     * @param addressesRegistry The addresses Registry contract address
     * @param stableYieldAddress The stable yield contract address
     * @param yieldReserve The old yield reserve
     */
    function depositIntoStableYield(
        uint256 amount,
        address addressesRegistry,
        address stableYieldAddress,
        uint256 yieldReserve
    ) external returns (uint256) {
        emit YieldDeposited(msg.sender, amount, stableYieldAddress);
        IStablecoinYieldConnector(
            IConnectorRouter(IAddressesRegistry(addressesRegistry).getConnectorsRouter()).getStablecoinYieldConnectorContract(
                stableYieldAddress
            )
        ).depositUSDC(amount);

        // Return the updated yield reserve value
        return yieldReserve + amount;
    }

    /**
     * @dev Function to withdraw stablecoins from the yield generating protocol to the liquidity pool
     * @param amount The amount of stablecoins
     * @param addressesRegistry The addresses Registry contract address
     * @param stableYieldAddress The stable yield contract address
     * @param yieldReserve The old yield reserve
     */
    function withdrawFromStableYield(
        uint256 amount,
        address addressesRegistry,
        address stableYieldAddress,
        uint256 yieldReserve
    ) external returns (uint256) {
        require(msg.sender != address(0), Errors.ADDRESS_IS_ZERO);
        IStablecoinYieldConnector stableConnector = IStablecoinYieldConnector(
            IConnectorRouter(IAddressesRegistry(addressesRegistry).getConnectorsRouter()).getStablecoinYieldConnectorContract(
                stableYieldAddress
            )
        );
        address aTokenAddress = stableConnector.getATokenAddress();
        require(IERC20(aTokenAddress).balanceOf(address(this)) >= amount, Errors.INVALID_AMOUNT);
        emit YieldWithdrawn(msg.sender, amount, stableYieldAddress);
        bool approveReturn = IERC20(aTokenAddress).approve(address(stableConnector), amount);
        require(approveReturn, Errors.APPROVAL_FAILED);
        stableConnector.withdrawUSDC(amount, amount);
        // Return the updated yield reserve value
        return yieldReserve - amount;
    }

    /**
     * @dev Function to withdraw fees by a caller that is either the royalties or protocol address
     * @param user The caller
     * @param to The address to send the funds to
     * @param amount The amount to withdraw
     * @param feeType The type of the fees to withdraw
     * @param poolData The pool data
     */
    function withdrawFees(
        address user,
        address to,
        uint256 amount,
        DataTypes.FeeType feeType,
        DataTypes.PoolData storage poolData
    ) external {
        //If withdrawing royalties and the msg.sender matches the royalties address
        if (feeType == DataTypes.FeeType.royalties && user == poolData.fee.royaltiesAddress && amount <= poolData.fee.royaltiesBalance) {
            poolData.fee.royaltiesBalance -= amount;
            emit WithdrawnFees(user, to, amount, "royalties");
            ILPToken(poolData.poolLPToken).setApproval20(poolData.stable, amount);
            IERC20(poolData.stable).safeTransferFrom(poolData.poolLPToken, to, amount);
        }
        //If withdrawing protocol fees and the msg.sender matches the protocol address
        if (feeType == DataTypes.FeeType.protocol && user == poolData.fee.protocolFeeAddress && amount <= poolData.fee.protocolBalance) {
            poolData.fee.protocolBalance -= amount;
            emit WithdrawnFees(user, to, amount, "protocol");
            ILPToken(poolData.poolLPToken).setApproval20(poolData.stable, amount);
            IERC20(poolData.stable).safeTransferFrom(poolData.poolLPToken, to, amount);
        }
    }
}