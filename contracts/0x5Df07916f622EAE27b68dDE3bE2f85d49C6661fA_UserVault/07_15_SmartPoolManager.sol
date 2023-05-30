// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// Needed to pass in structs
pragma experimental ABIEncoderV2;

// Imports

import "../interfaces/IERC20.sol";
import "../interfaces/IConfigurableRightsPool.sol";
import "../interfaces/IBFactory.sol"; // unused
import "./DesynSafeMath.sol";
import "./SafeMath.sol";
import "./SafeApprove.sol";

/**
 * @author Desyn Labs
 * @title Factor out the weight updates
 */
library SmartPoolManager {
    using SafeApprove for IERC20;
    using DesynSafeMath for uint;
    using SafeMath for uint;

    //kol pool params
    struct levelParams {
        uint level;
        uint ratio;
    }

    struct feeParams {
        levelParams firstLevel;
        levelParams secondLevel;
        levelParams thirdLevel;
        levelParams fourLevel;
    }
    
    struct KolPoolParams {
        feeParams managerFee;
        feeParams issueFee;
        feeParams redeemFee;
        feeParams perfermanceFee;
    }

    // Type declarations
    enum Etypes {
        OPENED,
        CLOSED
    }

    enum Period {
        HALF,
        ONE,
        TWO
    }

    // updateWeight and pokeWeights are unavoidably long
    /* solhint-disable function-max-lines */
    struct Status {
        uint collectPeriod;
        uint collectEndTime;
        uint closurePeriod;
        uint closureEndTime;
        uint upperCap;
        uint floorCap;
        uint managerFee;
        uint redeemFee;
        uint issueFee;
        uint perfermanceFee;
        uint startClaimFeeTime;
    }

    struct PoolParams {
        // Desyn Pool Token (representing shares of the pool)
        string poolTokenSymbol;
        string poolTokenName;
        // Tokens inside the Pool
        address[] constituentTokens;
        uint[] tokenBalances;
        uint[] tokenWeights;
        uint swapFee;
        uint managerFee;
        uint redeemFee;
        uint issueFee;
        uint perfermanceFee;
        Etypes etype;
    }

    struct PoolTokenRange {
        uint bspFloor;
        uint bspCap;
    }

    struct Fund {
        uint etfAmount;
        uint fundAmount;
    }

    function initRequire(
        uint swapFee,
        uint managerFee,
        uint issueFee,
        uint redeemFee,
        uint perfermanceFee,
        uint tokenBalancesLength,
        uint tokenWeightsLength,
        uint constituentTokensLength,
        bool initBool
    ) external pure {
        // We don't have a pool yet; check now or it will fail later (in order of likelihood to fail)
        // (and be unrecoverable if they don't have permission set to change it)
        // Most likely to fail, so check first
        require(!initBool, "Init fail");
        require(swapFee >= DesynConstants.MIN_FEE, "ERR_INVALID_SWAP_FEE");
        require(swapFee <= DesynConstants.MAX_FEE, "ERR_INVALID_SWAP_FEE");
        require(managerFee >= DesynConstants.MANAGER_MIN_FEE, "ERR_INVALID_MANAGER_FEE");
        require(managerFee <= DesynConstants.MANAGER_MAX_FEE, "ERR_INVALID_MANAGER_FEE");
        require(issueFee >= DesynConstants.ISSUE_MIN_FEE, "ERR_INVALID_ISSUE_MIN_FEE");
        require(issueFee <= DesynConstants.ISSUE_MAX_FEE, "ERR_INVALID_ISSUE_MAX_FEE");
        require(redeemFee >= DesynConstants.REDEEM_MIN_FEE, "ERR_INVALID_REDEEM_MIN_FEE");
        require(redeemFee <= DesynConstants.REDEEM_MAX_FEE, "ERR_INVALID_REDEEM_MAX_FEE");
        require(perfermanceFee >= DesynConstants.PERFERMANCE_MIN_FEE, "ERR_INVALID_PERFERMANCE_MIN_FEE");
        require(perfermanceFee <= DesynConstants.PERFERMANCE_MAX_FEE, "ERR_INVALID_PERFERMANCE_MAX_FEE");

        // Arrays must be parallel
        require(tokenBalancesLength == constituentTokensLength, "ERR_START_BALANCES_MISMATCH");
        require(tokenWeightsLength == constituentTokensLength, "ERR_START_WEIGHTS_MISMATCH");
        // Cannot have too many or too few - technically redundant, since BPool.bind() would fail later
        // But if we don't check now, we could have a useless contract with no way to create a pool

        require(constituentTokensLength >= DesynConstants.MIN_ASSET_LIMIT, "ERR_TOO_FEW_TOKENS");
        require(constituentTokensLength <= DesynConstants.MAX_ASSET_LIMIT, "ERR_TOO_MANY_TOKENS");
        // There are further possible checks (e.g., if they use the same token twice), but
        // we can let bind() catch things like that (i.e., not things that might reasonably work)
    }

    /**
     * @notice Update the weight of an existing token
     * @dev Refactored to library to make CRPFactory deployable
     * @param self - ConfigurableRightsPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param tokenA - token to sell
     * @param tokenB - token to buy
     */
    function rebalance(
        IConfigurableRightsPool self,
        IBPool bPool,
        address tokenA,
        address tokenB,
        uint deltaWeight,
        uint minAmountOut
    ) external {
        uint currentWeightA = bPool.getDenormalizedWeight(tokenA);
        uint currentBalanceA = bPool.getBalance(tokenA);
        // uint currentWeightB = bPool.getDenormalizedWeight(tokenB);

        require(deltaWeight <= currentWeightA, "ERR_DELTA_WEIGHT_TOO_BIG");

        // deltaBalance = currentBalance * (deltaWeight / currentWeight)
        uint deltaBalanceA = DesynSafeMath.bmul(currentBalanceA, DesynSafeMath.bdiv(deltaWeight, currentWeightA));

        // uint currentBalanceB = bPool.getBalance(tokenB);

        // uint deltaWeight = DesynSafeMath.bsub(newWeight, currentWeightA);

        // uint newWeightB = DesynSafeMath.bsub(currentWeightB, deltaWeight);
        // require(newWeightB >= 0, "ERR_INCORRECT_WEIGHT_B");
        bool soldout;
        if (deltaWeight == currentWeightA) {
            // reduct token A
            bPool.unbindPure(tokenA);
            soldout = true;
        }

        // Now with the tokens this contract can bind them to the pool it controls
        bPool.rebindSmart(tokenA, tokenB, deltaWeight, deltaBalanceA, soldout, minAmountOut);
    }

    /**
     * @notice Non ERC20-conforming tokens are problematic; don't allow them in pools
     * @dev Will revert if invalid
     * @param token - The prospective token to verify
     */
    function verifyTokenCompliance(address token) external {
        verifyTokenComplianceInternal(token);
    }

    /**
     * @notice Non ERC20-conforming tokens are problematic; don't allow them in pools
     * @dev Will revert if invalid - overloaded to save space in the main contract
     * @param tokens - The prospective tokens to verify
     */
    function verifyTokenCompliance(address[] calldata tokens) external {
        for (uint i = 0; i < tokens.length; i++) {
            verifyTokenComplianceInternal(tokens[i]);
        }
    }

    function createPoolInternalHandle(IBPool bPool, uint initialSupply) external view {
        require(initialSupply >= DesynConstants.MIN_POOL_SUPPLY, "ERR_INIT_SUPPLY_MIN");
        require(initialSupply <= DesynConstants.MAX_POOL_SUPPLY, "ERR_INIT_SUPPLY_MAX");
        require(bPool.EXIT_FEE() == 0, "ERR_NONZERO_EXIT_FEE");
        // EXIT_FEE must always be zero, or ConfigurableRightsPool._pushUnderlying will fail
        require(DesynConstants.EXIT_FEE == 0, "ERR_NONZERO_EXIT_FEE");
    }

    function createPoolHandle(
        uint collectPeriod,
        uint upperCap,
        uint initialSupply
    ) external pure {
        require(collectPeriod <= DesynConstants.MAX_COLLECT_PERIOD, "ERR_EXCEEDS_FUND_RAISING_PERIOD");
        require(upperCap >= initialSupply, "ERR_CAP_BIGGER_THAN_INITSUPPLY");
    }

    function exitPoolHandle(
        uint _endEtfAmount,
        uint _endFundAmount,
        uint _beginEtfAmount,
        uint _beginFundAmount,
        uint poolAmountIn,
        uint totalEnd
    )
        external
        pure
        returns (
            uint endEtfAmount,
            uint endFundAmount,
            uint profitRate
        )
    {
        endEtfAmount = DesynSafeMath.badd(_endEtfAmount, poolAmountIn);
        endFundAmount = DesynSafeMath.badd(_endFundAmount, totalEnd);
        uint amount1 = DesynSafeMath.bdiv(endFundAmount, endEtfAmount);
        uint amount2 = DesynSafeMath.bdiv(_beginFundAmount, _beginEtfAmount);
        if (amount1 > amount2) {
            profitRate = DesynSafeMath.bdiv(
                DesynSafeMath.bmul(DesynSafeMath.bsub(DesynSafeMath.bdiv(endFundAmount, endEtfAmount), DesynSafeMath.bdiv(_beginFundAmount, _beginEtfAmount)), poolAmountIn),
                totalEnd
            );
        }
    }

    function exitPoolHandleA(
        IConfigurableRightsPool self,
        IBPool bPool,
        address poolToken,
        uint _tokenAmountOut,
        uint redeemFee,
        uint profitRate,
        uint perfermanceFee
    )
        external
        returns (
            uint redeemAndPerformanceFeeReceived,
            uint finalAmountOut,
            uint redeemFeeReceived
        )
    {
        // redeem fee
        redeemFeeReceived = DesynSafeMath.bmul(_tokenAmountOut, redeemFee);

        // performance fee
        uint performanceFeeReceived = DesynSafeMath.bmul(DesynSafeMath.bmul(_tokenAmountOut, profitRate), perfermanceFee);
        
        // redeem fee and performance fee
        redeemAndPerformanceFeeReceived = DesynSafeMath.badd(performanceFeeReceived, redeemFeeReceived);

        // final amount the user got
        finalAmountOut = DesynSafeMath.bsub(_tokenAmountOut, redeemAndPerformanceFeeReceived);

        _pushUnderlying(bPool, poolToken, msg.sender, finalAmountOut);

        if (redeemFee != 0 || (profitRate > 0 && perfermanceFee != 0)) {
            _pushUnderlying(bPool, poolToken, address(this), redeemAndPerformanceFeeReceived);
            IERC20(poolToken).safeApprove(self.vaultAddress(), redeemAndPerformanceFeeReceived);
        }
    }

    function exitPoolHandleB(
        IConfigurableRightsPool self,
        bool bools,
        bool isCompletedCollect,
        uint closureEndTime,
        uint collectEndTime,
        uint _etfAmount,
        uint _fundAmount,
        uint poolAmountIn
    ) external view returns (uint etfAmount, uint fundAmount, uint actualPoolAmountIn) {
        actualPoolAmountIn = poolAmountIn;
        if (bools) {
            bool isCloseEtfCollectEndWithFailure = isCompletedCollect == false && block.timestamp >= collectEndTime;
            bool isCloseEtfClosureEnd = block.timestamp >= closureEndTime;
            require(isCloseEtfCollectEndWithFailure || isCloseEtfClosureEnd, "ERR_CLOSURE_TIME_NOT_ARRIVED!");

            actualPoolAmountIn = self.balanceOf(msg.sender);
        }
        fundAmount = _fundAmount;
        etfAmount = _etfAmount;
    }

    function joinPoolHandle(
        bool canWhitelistLPs,
        bool isList,
        bool bools,
        uint collectEndTime
    ) external view {
        require(!canWhitelistLPs || isList, "ERR_NOT_ON_WHITELIST");

        if (bools) {
            require(block.timestamp <= collectEndTime, "ERR_COLLECT_PERIOD_FINISHED!");
        }
    }

    function rebalanceHandle(
        IBPool bPool,
        bool isCompletedCollect,
        bool bools,
        uint collectEndTime,
        uint closureEndTime,
        bool canChangeWeights,
        address tokenA,
        address tokenB
    ) external {
        require(bPool.isBound(tokenA), "ERR_TOKEN_NOT_BOUND");
        if (bools) {
            require(isCompletedCollect, "ERROR_COLLECTION_FAILED");
            require(block.timestamp > collectEndTime && block.timestamp < closureEndTime, "ERR_NOT_REBALANCE_PERIOD");
        }

        if (!bPool.isBound(tokenB)) {
            bool returnValue = IERC20(tokenB).safeApprove(address(bPool), DesynConstants.MAX_UINT);
            require(returnValue, "ERR_ERC20_FALSE");
        }

        require(canChangeWeights, "ERR_NOT_CONFIGURABLE_WEIGHTS");
        require(tokenA != tokenB, "ERR_TOKENS_SAME");
    }

    /**
     * @notice Join a pool
     * @param self - ConfigurableRightsPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param poolAmountOut - number of pool tokens to receive
     * @param maxAmountsIn - Max amount of asset tokens to spend
     * @return actualAmountsIn - calculated values of the tokens to pull in
     */
    function joinPool(
        IConfigurableRightsPool self,
        IBPool bPool,
        uint poolAmountOut,
        uint[] calldata maxAmountsIn,
        uint issueFee
    ) external view returns (uint[] memory actualAmountsIn) {
        address[] memory tokens = bPool.getCurrentTokens();

        require(maxAmountsIn.length == tokens.length, "ERR_AMOUNTS_MISMATCH");

        uint poolTotal = self.totalSupply();
        // Subtract  1 to ensure any rounding errors favor the pool
        uint ratio = DesynSafeMath.bdiv(poolAmountOut, DesynSafeMath.bsub(poolTotal, 1));

        require(ratio != 0, "ERR_MATH_APPROX");

        // We know the length of the array; initialize it, and fill it below
        // Cannot do "push" in memory
        actualAmountsIn = new uint[](tokens.length);

        // This loop contains external calls
        // External calls are to math libraries or the underlying pool, so low risk
        uint issueFeeRate = issueFee.bmul(1000);
        for (uint i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            uint bal = bPool.getBalance(t);
            // Add 1 to ensure any rounding errors favor the pool
            uint base = bal.badd(1).bmul(poolAmountOut * uint(1000));
            uint tokenAmountIn = base.bdiv(poolTotal.bsub(1) * (uint(1000).bsub(issueFeeRate)));

            require(tokenAmountIn != 0, "ERR_MATH_APPROX");
            require(tokenAmountIn <= maxAmountsIn[i], "ERR_LIMIT_IN");

            actualAmountsIn[i] = tokenAmountIn;
        }
    }

    /**
     * @notice Exit a pool - redeem pool tokens for underlying assets
     * @param self - ConfigurableRightsPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param poolAmountIn - amount of pool tokens to redeem
     * @param minAmountsOut - minimum amount of asset tokens to receive
     * @return actualAmountsOut - calculated amounts of each token to pull
     */
    function exitPool(
        IConfigurableRightsPool self,
        IBPool bPool,
        uint poolAmountIn,
        uint[] calldata minAmountsOut
    ) external view returns (uint[] memory actualAmountsOut) {
        address[] memory tokens = bPool.getCurrentTokens();

        require(minAmountsOut.length == tokens.length, "ERR_AMOUNTS_MISMATCH");

        uint poolTotal = self.totalSupply();

        uint ratio = DesynSafeMath.bdiv(poolAmountIn, DesynSafeMath.badd(poolTotal, 1));

        require(ratio != 0, "ERR_MATH_APPROX");

        actualAmountsOut = new uint[](tokens.length);

        // This loop contains external calls
        // External calls are to math libraries or the underlying pool, so low risk
        for (uint i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            uint bal = bPool.getBalance(t);
            // Subtract 1 to ensure any rounding errors favor the pool
            uint tokenAmountOut = DesynSafeMath.bmul(ratio, DesynSafeMath.bsub(bal, 1));

            require(tokenAmountOut != 0, "ERR_MATH_APPROX");
            require(tokenAmountOut >= minAmountsOut[i], "ERR_LIMIT_OUT");

            actualAmountsOut[i] = tokenAmountOut;
        }
    }

    // Internal functions
    // Check for zero transfer, and make sure it returns true to returnValue
    function verifyTokenComplianceInternal(address token) internal {
        bool returnValue = IERC20(token).transfer(msg.sender, 0);
        require(returnValue, "ERR_NONCONFORMING_TOKEN");
    }

    function handleTransferInTokens(
        IConfigurableRightsPool self,
        IBPool bPool,
        address poolToken,
        uint actualAmountIn,
        uint _actualIssueFee
    ) external returns (uint issueFeeReceived) {
        issueFeeReceived = DesynSafeMath.bmul(actualAmountIn, _actualIssueFee);
        uint amount = DesynSafeMath.bsub(actualAmountIn, issueFeeReceived);

        _pullUnderlying(bPool, poolToken, msg.sender, amount);

        if (_actualIssueFee != 0) {
            bool xfer = IERC20(poolToken).transferFrom(msg.sender, address(this), issueFeeReceived);
            require(xfer, "ERR_ERC20_FALSE");

            IERC20(poolToken).safeApprove(self.vaultAddress(), issueFeeReceived);
        }
    }

    function handleClaim(
        IConfigurableRightsPool self,
        IBPool bPool,
        address[] calldata poolTokens,
        uint managerFee,
        uint timeElapsed,
        uint claimPeriod
    ) external returns (uint[] memory) {
        uint[] memory tokensAmount = new uint[](poolTokens.length);
        
        for (uint i = 0; i < poolTokens.length; i++) {
            address t = poolTokens[i];
            uint tokenBalance = bPool.getBalance(t);
            uint tokenAmountOut = tokenBalance.bmul(managerFee).mul(timeElapsed).div(claimPeriod).div(12);    
            _pushUnderlying(bPool, t, address(this), tokenAmountOut);
            IERC20(t).safeApprove(self.vaultAddress(), tokenAmountOut);
            tokensAmount[i] = tokenAmountOut;
        }
        
        return tokensAmount;
    }

    function handleCollectionCompleted(
        IConfigurableRightsPool self,
        IBPool bPool,
        address[] calldata poolTokens,
        uint issueFee
    ) external {
        if (issueFee != 0) {
            uint[] memory tokensAmount = new uint[](poolTokens.length);

            for (uint i = 0; i < poolTokens.length; i++) {
                address t = poolTokens[i];
                uint currentAmount = bPool.getBalance(t);
                uint currentAmountFee = DesynSafeMath.bmul(currentAmount, issueFee);

                _pushUnderlying(bPool, t, address(this), currentAmountFee);
                tokensAmount[i] = currentAmountFee;
                IERC20(t).safeApprove(self.vaultAddress(), currentAmountFee);
            }

            IVault(self.vaultAddress()).depositIssueRedeemPToken(poolTokens, tokensAmount, tokensAmount, false);
        }
    }

    function WhitelistHandle(
        bool bool1,
        bool bool2,
        address adr
    ) external pure {
        require(bool1, "ERR_CANNOT_WHITELIST_LPS");
        require(bool2, "ERR_LP_NOT_WHITELISTED");
        require(adr != address(0), "ERR_INVALID_ADDRESS");
    }

    function _pullUnderlying(
        IBPool bPool,
        address erc20,
        address from,
        uint amount
    ) internal {
        uint tokenBalance = bPool.getBalance(erc20);
        uint tokenWeight = bPool.getDenormalizedWeight(erc20);

        bool xfer = IERC20(erc20).transferFrom(from, address(this), amount);
        require(xfer, "ERR_ERC20_FALSE");
        bPool.rebind(erc20, DesynSafeMath.badd(tokenBalance, amount), tokenWeight);
    }

    function _pushUnderlying(
        IBPool bPool,
        address erc20,
        address to,
        uint amount
    ) internal {
        uint tokenBalance = bPool.getBalance(erc20);
        uint tokenWeight = bPool.getDenormalizedWeight(erc20);
        bPool.rebind(erc20, DesynSafeMath.bsub(tokenBalance, amount), tokenWeight);
        bool xfer = IERC20(erc20).transfer(to, amount);
        require(xfer, "ERR_ERC20_FALSE");
    }
}