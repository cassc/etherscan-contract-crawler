// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

/*
                                      s███
                                    ██████
                                   @██████
                              ,s███`
                           ,██████████████
                          █████████^@█████_
                         ██████████_ [email protected]███_            "██████████M
                        @██████████_     `_              "@█████b
                        ^^^^^^^^^^"                         ^"`
                         
                        ████████████████████p   _█████████████████████
                        @████████████████████   @███████████[email protected]██████b
                         ████████████████████   @███████████  ,██████
                         @███████████████████   @███████████████████b
                          @██████████████████   @██████████████████b
                           "█████████████████   @█████████████████b
                             @███████████████   @████████████████
                               %█████████████   @██████████████`
                                 ^%██████████   @███████████"
                                     ████████   @██████W"`
                                     1███████
                                      "@█████
                                         [email protected]█
*/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "./ChainlinkUtils.sol";
import "./SafeguardMath.sol";
import "./SignatureSafeguard.sol";
import "@balancer-labs/v2-pool-utils/contracts/BasePool.sol";
import "@balancer-labs/v2-interfaces/contracts/vault/IMinimalSwapInfoPool.sol";
import "@balancer-labs/v2-solidity-utils/contracts/helpers/EOASignaturesValidator.sol";
import "@balancer-labs/v2-solidity-utils/contracts/openzeppelin/ReentrancyGuard.sol";
import "@balancer-labs/v2-pool-utils/contracts/lib/BasePoolMath.sol";
import "@swaap-labs/v2-interfaces/contracts/safeguard-pool/SafeguardPoolUserData.sol";
import "@swaap-labs/v2-interfaces/contracts/safeguard-pool/ISafeguardPool.sol";
import "@swaap-labs/v2-errors/contracts/SwaapV2Errors.sol";

/**
 * @title Safeguard Pool
 * @author Swaap-labs (https://github.com/swaap-labs/swaap-v2-monorepo)
 * @notice Main contract that allows the use of a non-custodial RfQ market-making infrastructure that
 * implements safety measures (i.e "safeguards") to prevent potential value extraction from the pool.
 * For more details: https://www.swaap.finance/v2-whitepaper.pdf.
 * @dev This contract is built on top of Balancer V2's infrastructure but is meant to be deployed with
 * a modified version of Balancer V2 Vault. (refer to the comments in the `updatePerformance` function
 * for more details).
 */
contract SafeguardPool is ISafeguardPool, SignatureSafeguard, BasePool, IMinimalSwapInfoPool, ReentrancyGuard {

    using FixedPoint for uint256;
    using WordCodec for bytes32;
    using BasePoolUserData for bytes;
    using SafeguardPoolUserData for bytes32;
    using SafeguardPoolUserData for bytes;

    uint256 private constant _NUM_TOKENS = 2;
    
    // initial BPT minted at the initialization of the pool
    uint256 private constant _INITIAL_BPT = 100 ether;
    // minimum acceptable balance at the initialization of the pool (balance upscaled to 18 decimals)
    uint256 private constant _MIN_INITIAL_BALANCE = 1e8;

    // Pool parameters constants
    uint256 private constant _MIN_SWAP_AMOUNT_PERCENTAGE = 10e16; // 10% min swap amount
    uint256 private constant _MAX_PERFORMANCE_DEVIATION = 95e16; // 5% max tolerance
    uint256 private constant _MAX_TARGET_DEVIATION = 80e16; // 20% max tolerance
    uint256 private constant _MAX_PRICE_DEVIATION = 97e16; // 3% max tolerance
    uint256 private constant _MIN_PERFORMANCE_UPDATE_INTERVAL = 0.5 days;
    uint256 private constant _MAX_PERFORMANCE_UPDATE_INTERVAL = 1.5 days;
    uint256 private constant _MAX_ORACLE_TIMEOUT = 1.5 days;

    // NB Max yearly fee should fit in a 32 bits slot
    uint256 private constant _MAX_YEARLY_FEES = 5e16; // corresponds to 5% fees

    IERC20 internal immutable _token0;
    IERC20 internal immutable _token1;
    
    AggregatorV3Interface internal immutable _oracle0;
    AggregatorV3Interface internal immutable _oracle1;

    uint256 internal immutable _maxOracleTimeout0;
    uint256 internal immutable _maxOracleTimeout1;

    bool internal immutable _isStable0;
    bool internal immutable _isStable1;

    uint256 internal constant _REPEG_PRICE_BOUND = 0.002e18; // repegs at 0.2%
    uint256 internal constant _UNPEG_PRICE_BOUND = 0.005e18; // unpegs at 0.5%

    // tokens scale factor
    uint256 internal immutable _scaleFactor0;
    uint256 internal immutable _scaleFactor1;

    // oracle price scale factor
    uint256 internal immutable _priceScaleFactor0;
    uint256 internal immutable _priceScaleFactor1;

    // quote signer
    address private _signer;

    // Allowlist enabled / disabled
    bool private _mustAllowlistLPs;

    // Management fees related variables
    uint32 private _previousClaimTime;
    // NB For a max yearly fee of 10% it is safe to use 32 bits for the yearlyRate.
    // For higher fees more bits should be allocated.
    uint32 private _yearlyRate;
    // yearly management fees
    uint64 private _yearlyFees;

    // solhint-disable max-line-length
    // [ isPegged0 | isPegged1 | flexibleOracle0 | flexibleOracle1 | max performance dev | max hodl dev | max price dev | perf update interval | last perf update ]
    // [   1 bit   |   1 bit   |      1 bit      |      1 bit      |       60 bits       |    64 bits   |    64 bits    |        32 bits       |      32 bits     ]
    // [ MSB                                                                                                                                                  LSB ]
    bytes32 private _packedPoolParams;
    // solhint-enable max-line-length

    // used to determine if stable coin is holding the peg
    uint256 private constant _TOKEN_0_PEGGED_BIT_OFFSET = 255;
    uint256 private constant _TOKEN_1_PEGGED_BIT_OFFSET = 254;

    // used to determine if the oracle can be pegged to a fixed value
    uint256 private constant _FLEXIBLE_ORACLE_0_BIT_OFFSET = 253;
    uint256 private constant _FLEXIBLE_ORACLE_1_BIT_OFFSET = 252;

    // used to determine if the pool is underperforming compared to the last performance update
    uint256 private constant _MAX_PERF_DEV_BIT_OFFSET = 192;
    uint256 private constant _MAX_PERF_DEV_BIT_LENGTH = 60;

    // used to determine if the pool balances deviated from the hodl reference
    uint256 private constant _MAX_TARGET_DEV_BIT_OFFSET = 128;
    uint256 private constant _MAX_TARGET_DEV_BIT_LENGTH = 64;

    // used to determine if the quote's price is too low compared to the oracle's price
    uint256 private constant _MAX_PRICE_DEV_BIT_OFFSET = 64;
    uint256 private constant _MAX_PRICE_DEV_BIT_LENGTH = 64;

    // used to determine if a performance update is needed before a swap / one-asset-join / one-asset-exit
    uint256 private constant _PERF_UPDATE_INTERVAL_BIT_OFFSET = 32;
    uint256 private constant _PERF_LAST_UPDATE_BIT_OFFSET = 0;
    uint256 private constant _PERF_TIME_BIT_LENGTH = 32;
    
    // [ min balance 0 per PT | min balance 1 per PT ]
    // [       128 bits       |       128 bits       ]
    // [ MSB                                     LSB ]
    bytes32 private _hodlBalancesPerPT; // benchmark target reserves based on performance

    uint256 private constant _HODL_BALANCE_BIT_OFFSET_0 = 128;
    uint256 private constant _HODL_BALANCE_BIT_OFFSET_1 = 0;
    uint256 private constant _HODL_BALANCE_BIT_LENGTH   = 128;

    constructor(
        IVault vault,
        string memory name,
        string memory symbol,
        IERC20[] memory tokens,
        address[] memory assetManagers,
        uint256 pauseWindowDuration,
        uint256 bufferPeriodDuration,
        address owner,
        InitialOracleParams[] memory oracleParams,
        InitialSafeguardParams memory safeguardParameters
    )
        BasePool(
            vault,
            IVault.PoolSpecialization.TWO_TOKEN,
            name,
            symbol,
            tokens,
            assetManagers,
            _getMinSwapFeePercentage(),
            pauseWindowDuration,
            bufferPeriodDuration,
            owner
        )
    {

        InputHelpers.ensureInputLengthMatch(tokens.length, _NUM_TOKENS);
        InputHelpers.ensureInputLengthMatch(oracleParams.length, _NUM_TOKENS);

        // token related parameters
        _token0 = IERC20(address(tokens[0]));
        _token1 = IERC20(address(tokens[1]));

        _scaleFactor0 = _computeScalingFactor(tokens[0]);
        _scaleFactor1 = _computeScalingFactor(tokens[1]);

        // oracle related parameters
        _oracle0 = oracleParams[0].oracle;
        _oracle1 = oracleParams[1].oracle;

        // oracles max price timeouts must be lower than 1.5 days
        _srequire(
            oracleParams[0].maxTimeout <= _MAX_ORACLE_TIMEOUT && oracleParams[1].maxTimeout <= _MAX_ORACLE_TIMEOUT,
            SwaapV2Errors.ORACLE_TIMEOUT_TOO_HIGH
        );

        // setting oracles price max timeouts
        _maxOracleTimeout0 = oracleParams[0].maxTimeout;
        _maxOracleTimeout1 = oracleParams[1].maxTimeout;

        // setting oracles price scale factors
        _priceScaleFactor0 = ChainlinkUtils.computePriceScalingFactor(oracleParams[0].oracle);
        _priceScaleFactor1 = ChainlinkUtils.computePriceScalingFactor(oracleParams[1].oracle);

        _isStable0 = oracleParams[0].isStable;
        _isStable1 = oracleParams[1].isStable;

        if(oracleParams[0].isStable && oracleParams[0].isFlexibleOracle) {
            _packedPoolParams = _packedPoolParams.insertBool(true, _FLEXIBLE_ORACLE_0_BIT_OFFSET);
        }

        if(oracleParams[1].isStable && oracleParams[1].isFlexibleOracle) {
            _packedPoolParams = _packedPoolParams.insertBool(true, _FLEXIBLE_ORACLE_1_BIT_OFFSET);
        }

        // pool related parameters
        _setSigner(safeguardParameters.signer);
        _setMaxPerfDev(safeguardParameters.maxPerfDev);
        _setMaxTargetDev(safeguardParameters.maxTargetDev);
        _setMaxPriceDev(safeguardParameters.maxPriceDev);
        _setPerfUpdateInterval(safeguardParameters.perfUpdateInterval);
        _previousClaimTime = uint32(block.timestamp); // _previousClaimTime is not updated in _setYearlyRate
        _setYearlyRate(safeguardParameters.yearlyFees);
        _setMustAllowlistLPs(safeguardParameters.mustAllowlistLPs);

    }

    function onSwap(
        SwapRequest calldata request,
        uint256 balanceTokenIn,
        uint256 balanceTokenOut
    ) external override onlyVault(request.poolId) returns (uint256) {

        _beforeSwapJoinExit();

        bool isTokenInToken0 = request.tokenIn == _token0;

        (bytes memory swapData, bytes32 digest) = _swapSignatureSafeguard(
            request.kind,
            isTokenInToken0,
            request.from,
            request.to,
            request.userData
        );
        
        (uint256 scalingFactorTokenIn, uint256 scalingFactorTokenOut) = _scalingFactorsInAndOut(isTokenInToken0);

        balanceTokenIn = _upscale(balanceTokenIn, scalingFactorTokenIn);
        balanceTokenOut = _upscale(balanceTokenOut, scalingFactorTokenOut);

        (uint256 quoteAmountInPerOut, uint256 maxSwapAmount) = 
            _getQuoteAmountInPerOut(swapData, balanceTokenIn, balanceTokenOut);

        if (request.kind == IVault.SwapKind.GIVEN_IN) {
            uint256 amountIn = request.amount;
            return _onSwapGivenIn(
                digest,
                isTokenInToken0,
                balanceTokenIn,
                balanceTokenOut,
                amountIn,
                quoteAmountInPerOut,
                maxSwapAmount,
                scalingFactorTokenIn,
                scalingFactorTokenOut
            );
        } else {
            uint256 amountOut = request.amount;
            return _onSwapGivenOut(
                digest,
                isTokenInToken0,
                balanceTokenIn,
                balanceTokenOut,
                amountOut,
                quoteAmountInPerOut,
                maxSwapAmount,
                scalingFactorTokenIn,
                scalingFactorTokenOut
            );
        }
    }

    /// @dev amountInPerOut = baseAmountInPerOut * (1 + slippagePenalty)
    function _getQuoteAmountInPerOut(
        bytes memory swapData,
        uint256 balanceTokenIn,
        uint256 balanceTokenOut
    ) internal view returns (uint256, uint256) {
        
        (
            address expectedOrigin,
            uint256 originBasedSlippage,
            bytes32 priceBasedParams,
            bytes32 quoteBalances,
            uint256 quoteTotalSupply,
            bytes32 balanceBasedParams,
            bytes32 timeBasedParams
        ) = swapData.pricingParameters();
        
        uint256 penalty = _getBalanceBasedPenalty(
            balanceTokenIn,
            balanceTokenOut,
            quoteBalances,
            quoteTotalSupply,
            balanceBasedParams
        );
        
        penalty = penalty.add(_getTimeBasedPenalty(timeBasedParams));

        penalty = penalty.add(SafeguardMath.calcOriginBasedPenalty(expectedOrigin, originBasedSlippage));

        (uint256 quoteAmountInPerOut, uint256 maxSwapAmount) = priceBasedParams.unpackPairedUints();

        penalty = penalty.add(FixedPoint.ONE);

        return (quoteAmountInPerOut.mulUp(penalty), maxSwapAmount);
    }

    function _getBalanceBasedPenalty(
        uint256 balanceTokenIn,
        uint256 balanceTokenOut,
        bytes32 quoteBalances,
        uint256 quoteTotalSupply,
        bytes32 balanceBasedParams
    ) internal view returns(uint256) 
    {
        (uint256 quoteBalanceIn, uint256 quoteBalanceOut) = quoteBalances.unpackPairedUints();

        (uint256 balanceChangeTolerance, uint256 balanceBasedSlippage) 
            = balanceBasedParams.unpackPairedUints();

        return SafeguardMath.calcBalanceBasedPenalty(
            balanceTokenIn,
            balanceTokenOut,
            totalSupply(),
            quoteBalanceIn,
            quoteBalanceOut,
            quoteTotalSupply,
            balanceChangeTolerance,
            balanceBasedSlippage
        );
    }

    function _getTimeBasedPenalty(bytes32 timeBasedParams) internal view returns(uint256) {
        (uint256 startTime, uint256 timeBasedSlippage) = timeBasedParams.unpackPairedUints();
        return SafeguardMath.calcTimeBasedPenalty(block.timestamp, startTime, timeBasedSlippage);
    }

    function _onSwapGivenIn(
        bytes32 digest,
        bool    isTokenInToken0,
        uint256 balanceTokenIn,
        uint256 balanceTokenOut,
        uint256 amountIn,
        uint256 quoteAmountInPerOut,
        uint256 maxSwapAmount,
        uint256 scalingFactorTokenIn,
        uint256 scalingFactorTokenOut
    ) internal returns(uint256) {
        amountIn = _upscale(amountIn, scalingFactorTokenIn);
        uint256 amountOut = amountIn.divDown(quoteAmountInPerOut);

        _validateSwap(
            digest,
            IVault.SwapKind.GIVEN_IN,
            isTokenInToken0,
            balanceTokenIn,
            balanceTokenOut,
            amountIn,
            amountOut,
            quoteAmountInPerOut,
            maxSwapAmount
        );

        return _downscaleDown(amountOut, scalingFactorTokenOut);
    }

    function _onSwapGivenOut(
        bytes32 digest,
        bool    isTokenInToken0,
        uint256 balanceTokenIn,
        uint256 balanceTokenOut,
        uint256 amountOut,
        uint256 quoteAmountInPerOut,
        uint256 maxSwapAmount,
        uint256 scalingFactorTokenIn,
        uint256 scalingFactorTokenOut
    ) internal returns(uint256) {
        amountOut = _upscale(amountOut, scalingFactorTokenOut);
        uint256 amountIn = amountOut.mulUp(quoteAmountInPerOut);

        _validateSwap(
            digest,
            IVault.SwapKind.GIVEN_OUT,
            isTokenInToken0,
            balanceTokenIn,
            balanceTokenOut,
            amountIn,
            amountOut,
            quoteAmountInPerOut,
            maxSwapAmount
        );

        return _downscaleUp(amountIn, scalingFactorTokenIn);
    }

    /**
    * @dev all the inputs should be normalized to 18 decimals regardless of token decimals
    */
    function _validateSwap(
        bytes32 digest,
        IVault.SwapKind kind,
        bool    isTokenInToken0,
        uint256 balanceTokenIn,
        uint256 balanceTokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 quoteAmountInPerOut,
        uint256 maxSwapAmount
    ) internal {

        if(kind == IVault.SwapKind.GIVEN_IN) {
            _srequire(amountIn <= maxSwapAmount, SwaapV2Errors.EXCEEDED_SWAP_AMOUNT_IN);
            _srequire(amountIn >= maxSwapAmount.mulDown(_MIN_SWAP_AMOUNT_PERCENTAGE), SwaapV2Errors.LOW_SWAP_AMOUNT_IN);
        } else {
            _srequire(amountOut <= maxSwapAmount, SwaapV2Errors.EXCEEDED_SWAP_AMOUNT_OUT);
            _srequire(amountOut >= maxSwapAmount.mulDown(_MIN_SWAP_AMOUNT_PERCENTAGE), SwaapV2Errors.LOW_SWAP_AMOUNT_OUT);
        }

        bytes32 packedPoolParams = _packedPoolParams;
        uint256 onChainAmountInPerOut = _getOnChainAmountInPerOut(packedPoolParams, isTokenInToken0);

        _fairPricingSafeguard(quoteAmountInPerOut, onChainAmountInPerOut, packedPoolParams);

        uint256 totalSupply = totalSupply();

        _updatePerformanceIfDue(
            isTokenInToken0,
            balanceTokenIn,
            balanceTokenOut,
            onChainAmountInPerOut,
            totalSupply,
            packedPoolParams
        );

        _balancesSafeguard(
            isTokenInToken0,
            balanceTokenIn.add(amountIn),
            balanceTokenOut.sub(amountOut),
            onChainAmountInPerOut,
            totalSupply,
            packedPoolParams
        );

        Quote(digest, amountIn, amountOut);
    }

    // ensures that the quote has a fair price compared to the on-chain price
    function _fairPricingSafeguard(
        uint256 quoteAmountInPerOut,
        uint256 onChainAmountInPerOut,
        bytes32 packedPoolParams
    ) internal pure {
        _srequire(quoteAmountInPerOut.divDown(onChainAmountInPerOut) >= _getMaxPriceDev(packedPoolParams), SwaapV2Errors.UNFAIR_PRICE);
    }

    // updates the pool target balances based on performance if needed
    function _updatePerformanceIfDue(
        bool    isTokenInToken0,
        uint256 currentBalanceIn,
        uint256 currentBalanceOut,
        uint256 onChainAmountInPerOut,
        uint256 totalSupply,
        bytes32 packedPoolParams
    ) internal {

        (uint256 lastPerfUpdate, uint256 perfUpdateInterval) = _getPerformanceTimeParams(packedPoolParams);

        // lastPerfUpdate & perfUpdateInterval are stored in 32 bits so they cannot overflow
        if(block.timestamp > lastPerfUpdate + perfUpdateInterval){
            if(isTokenInToken0){
                _updatePerformance(currentBalanceIn, currentBalanceOut, onChainAmountInPerOut, totalSupply);
            } else {
                _updatePerformance(
                    currentBalanceOut,
                    currentBalanceIn,
                    FixedPoint.ONE.divDown(onChainAmountInPerOut),
                    totalSupply
                );
            }
        }
    }

    function _balancesSafeguard(
        bool    isTokenInToken0,
        uint256 newBalanceIn,
        uint256 newBalanceOut,
        uint256 onChainAmountInPerOut,
        uint256 totalSupply,
        bytes32 packedPoolParams
    ) internal view {

        (uint256 newBalancePerPTIn, uint256 newBalancePerPTOut, uint256 hodlBalancePerPTIn, uint256 hodlBalancePerPTOut) 
            = _getBalancesPerPT(isTokenInToken0, newBalanceIn, newBalanceOut, totalSupply);
        
        // we check for performance only if the pool is not being rebalanced by the current swap
        if (newBalancePerPTOut < hodlBalancePerPTOut || newBalancePerPTIn > hodlBalancePerPTIn) {
            _srequire(
                _getPerfFromBalancesPerPT(
                    newBalancePerPTIn,
                    newBalancePerPTOut,
                    hodlBalancePerPTIn,
                    hodlBalancePerPTOut,
                    onChainAmountInPerOut
                ) >= _getMaxPerfDev(packedPoolParams), 
                SwaapV2Errors.LOW_PERFORMANCE
            );
        }

        _srequire(
            newBalancePerPTOut.divDown(hodlBalancePerPTOut) >= _getMaxTargetDev(packedPoolParams), 
            SwaapV2Errors.MIN_BALANCE_OUT_NOT_MET
        );
    }

    function _onInitializePool(
        bytes32, // poolId,
        address sender,
        address, // recipient,
        uint256[] memory scalingFactors,
        bytes memory userData
    ) internal override returns (uint256, uint256[] memory) {

        if(isAllowlistEnabled()) {
            userData = _isLPAllowed(sender, userData);
        }

        (SafeguardPoolUserData.JoinKind kind, uint256[] memory amountsIn) = userData.initJoin();
        
        _require(kind == SafeguardPoolUserData.JoinKind.INIT, Errors.UNINITIALIZED);
        _require(amountsIn.length == _NUM_TOKENS, Errors.TOKENS_LENGTH_MUST_BE_2);
        
        _upscaleArray(amountsIn, scalingFactors);

        // prevents the pool from being initialized with a low balance (i.e. amountIn = 1 wei)
        // which will result in an usuable pool at initialization since hodlBalancePerPT will be equal to 0 
        // and targeDeviation = currentBalancePerPT / hodlBalancePerPT (illegal division by 0)
        _srequire(
            amountsIn[0] >= _MIN_INITIAL_BALANCE && amountsIn[1] >= _MIN_INITIAL_BALANCE,
            SwaapV2Errors.LOW_INITIAL_BALANCE
        );

        // sets initial target balances
        uint256 initHodlBalancePerPT0 = amountsIn[0].divDown(_INITIAL_BPT);
        uint256 initHodlBalancePerPT1 = amountsIn[1].divDown(_INITIAL_BPT);
        _setHodlBalancesPerPT(initHodlBalancePerPT0, initHodlBalancePerPT1);

        emit InitialTargetBalancesSet(initHodlBalancePerPT0, initHodlBalancePerPT1);
        
        return (_INITIAL_BPT, amountsIn);
        
    }

    function _onJoinPool(
        bytes32, // poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256, // lastChangeBlock,
        uint256, // protocolSwapFeePercentage,
        uint256[] memory, // scalingFactors,
        bytes memory userData
    ) internal override returns (uint256 bptAmountOut, uint256[] memory amountsIn) {

        _beforeJoinExit();

        if(isAllowlistEnabled()) {
            userData = _isLPAllowed(sender, userData);
        }

        SafeguardPoolUserData.JoinKind kind = userData.joinKind();

        if(kind == SafeguardPoolUserData.JoinKind.ALL_TOKENS_IN_FOR_EXACT_BPT_OUT) {

            return _joinAllTokensInForExactBPTOut(balances, totalSupply(), userData);

        } else if (kind == SafeguardPoolUserData.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT) {

            return _joinExactTokensInForBPTOut(sender, recipient, balances, userData);

        } else {
            _revert(Errors.UNHANDLED_JOIN_KIND);
        }
    }

    function _isLPAllowed(address sender, bytes memory userData) internal returns(bytes memory) {
        // we subtiture userData by the joinData
        return _validateAllowlistSignature(sender, userData);
    }

    function _joinAllTokensInForExactBPTOut(
        uint256[] memory balances,
        uint256 totalSupply,
        bytes memory userData
    ) private  pure returns (uint256, uint256[] memory) {
              
        uint256 bptAmountOut = userData.allTokensInForExactBptOut();
        // Note that there is no maximum amountsIn parameter: this is handled by `IVault.joinPool`.

        uint256[] memory amountsIn = BasePoolMath.computeProportionalAmountsIn(balances, totalSupply, bptAmountOut);

        return (bptAmountOut, amountsIn);
    }

    function _joinExactTokensInForBPTOut(
        address sender,
        address recipient,
        uint256[] memory balances,
        bytes memory userData
    ) internal returns (uint256, uint256[] memory) {

        (
            uint256 minBptAmountOut,
            uint256[] memory joinAmounts,
            bool isExcessToken0,
            ValidatedQuoteData memory validatedQuoteData
        ) = _joinExitSwapSignatureSafeguard(sender, recipient, userData);

        (uint256 excessTokenBalance, uint256 limitTokenBalance) = isExcessToken0?
            (balances[0], balances[1]) : (balances[1], balances[0]);

        (uint256 quoteAmountInPerOut, uint256 maxSwapAmount) = _getQuoteAmountInPerOut(validatedQuoteData.swapData, excessTokenBalance, limitTokenBalance);
        
        (uint256 excessTokenAmountIn, uint256 limitTokenAmountIn) = isExcessToken0?
            (joinAmounts[0], joinAmounts[1]) : (joinAmounts[1], joinAmounts[0]);
        
        (
            uint256 swapAmountIn,
            uint256 swapAmountOut
        ) = SafeguardMath.calcJoinSwapAmounts(
            excessTokenBalance,
            limitTokenBalance,
            excessTokenAmountIn,
            limitTokenAmountIn,
            quoteAmountInPerOut
        );

        _validateSwap(
            validatedQuoteData.digest,
            IVault.SwapKind.GIVEN_IN,
            isExcessToken0,
            excessTokenBalance,
            limitTokenBalance,
            swapAmountIn,
            swapAmountOut,
            quoteAmountInPerOut,
            maxSwapAmount
        );

        uint256 rOpt = SafeguardMath.calcJoinSwapROpt(excessTokenBalance, excessTokenAmountIn, swapAmountIn);
        
        uint256 bptAmountOut = totalSupply().mulDown(rOpt);        
        _srequire(bptAmountOut >= minBptAmountOut, SwaapV2Errors.NOT_ENOUGH_PT_OUT);
        
        return (bptAmountOut, joinAmounts);

    }

    function _doRecoveryModeExit(
        uint256[] memory balances,
        uint256 totalSupply,
        bytes memory userData
    ) internal pure override returns (uint256 bptAmountIn, uint256[] memory amountsOut) {
        bptAmountIn = userData.recoveryModeExit();
        amountsOut = BasePoolMath.computeProportionalAmountsOut(balances, totalSupply, bptAmountIn);
    }

    function _onExitPool(
        bytes32, // poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256, // lastChangeBlock,
        uint256, // protocolSwapFeePercentage,
        uint256[] memory, // scalingFactors,
        bytes memory userData
    ) internal override returns (uint256 bptAmountIn, uint256[] memory amountsOut) {

        _beforeJoinExit();

        (SafeguardPoolUserData.ExitKind kind) = userData.exitKind();

        if(kind == SafeguardPoolUserData.ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT) {

            return _exitExactBPTInForTokensOut(balances, totalSupply(), userData);

        } else if (kind == SafeguardPoolUserData.ExitKind.BPT_IN_FOR_EXACT_TOKENS_OUT) {
            
            return _exitBPTInForExactTokensOut(sender, recipient, balances, userData);

        } else {
            _revert(Errors.UNHANDLED_EXIT_KIND);
        }

    }

    function _exitExactBPTInForTokensOut(
        uint256[] memory balances,
        uint256 totalSupply,
        bytes memory userData
    ) private returns (uint256, uint256[] memory) {
               
        // updates pool performance if necessary
        try this.updatePerformance() {} catch {}
        
        uint256 bptAmountIn = userData.exactBptInForTokensOut();
        // Note that there is no minimum amountOut parameter: this is handled by `IVault.exitPool`.

        uint256[] memory amountsOut = BasePoolMath.computeProportionalAmountsOut(balances, totalSupply, bptAmountIn);
        return (bptAmountIn, amountsOut);
    }

    function _exitBPTInForExactTokensOut(
        address sender,
        address recipient,
        uint256[] memory balances,
        bytes memory userData
    ) internal returns (uint256, uint256[] memory) {
        
        (
            uint256 maxBptAmountIn,
            uint256[] memory exitAmounts,
            bool isLimitToken0,
            ValidatedQuoteData memory validatedQuoteData
        ) = _joinExitSwapSignatureSafeguard(sender, recipient, userData);

        (uint256 excessTokenBalance, uint256 limitTokenBalance) = isLimitToken0?
            (balances[1], balances[0]) : (balances[0], balances[1]);

        (uint256 quoteAmountInPerOut, uint256 maxSwapAmount) = _getQuoteAmountInPerOut(validatedQuoteData.swapData, limitTokenBalance, excessTokenBalance);

        (uint256 excessTokenAmountOut, uint256 limitTokenAmountOut) = isLimitToken0?
            (exitAmounts[1], exitAmounts[0]) : (exitAmounts[0], exitAmounts[1]);

        (
            uint256 swapAmountIn,
            uint256 swapAmountOut
        ) = SafeguardMath.calcExitSwapAmounts(
            excessTokenBalance,
            limitTokenBalance,
            excessTokenAmountOut,
            limitTokenAmountOut,
            quoteAmountInPerOut
        );

        _validateSwap(
            validatedQuoteData.digest,
            IVault.SwapKind.GIVEN_IN,
            isLimitToken0,
            limitTokenBalance,
            excessTokenBalance,
            swapAmountIn,
            swapAmountOut,
            quoteAmountInPerOut,
            maxSwapAmount
        );

        uint256 rOpt = SafeguardMath.calcExitSwapROpt(excessTokenBalance, excessTokenAmountOut, swapAmountOut);
                
        uint256 bptAmountOut = totalSupply().mulUp(rOpt);
        
        _srequire(bptAmountOut <= maxBptAmountIn, SwaapV2Errors.EXCEEDED_BURNED_PT);
        
        return (bptAmountOut, exitAmounts);

    }

    /**
    * Setters
    */

    /// @inheritdoc ISafeguardPool
    function setFlexibleOracleStates(
        bool isFlexibleOracle0,
        bool isFlexibleOracle1
    ) external override authenticate whenNotPaused {
       
        bytes32 packedPoolParams = _packedPoolParams;

        if(_isStable0) {
            if(!isFlexibleOracle0) {
                // if the oracle is no longer flexible we need to reset the peg state
                packedPoolParams = packedPoolParams.insertBool(false, _TOKEN_0_PEGGED_BIT_OFFSET);
            }
            packedPoolParams = packedPoolParams.insertBool(isFlexibleOracle0, _FLEXIBLE_ORACLE_0_BIT_OFFSET);
        }

        if(_isStable1) {
            if(!isFlexibleOracle1) {
                // if the oracle is no longer flexible we need to reset the peg state
                packedPoolParams = packedPoolParams.insertBool(false, _TOKEN_1_PEGGED_BIT_OFFSET);
            }
            packedPoolParams = packedPoolParams.insertBool(isFlexibleOracle1, _FLEXIBLE_ORACLE_1_BIT_OFFSET);
        }

        _packedPoolParams = packedPoolParams;
        // we do not use the inputs of the function because they may not me update the state if the token isn't stable
        emit FlexibleOracleStatesUpdated(_isFlexibleOracle0(packedPoolParams), _isFlexibleOracle1(packedPoolParams));
    }

    /// @inheritdoc ISafeguardPool
    function setMustAllowlistLPs(bool mustAllowlistLPs) external override authenticate whenNotPaused {
        _setMustAllowlistLPs(mustAllowlistLPs);
    }

    function _setMustAllowlistLPs(bool mustAllowlistLPs) private {
        _mustAllowlistLPs = mustAllowlistLPs;
        emit MustAllowlistLPsSet(mustAllowlistLPs);
    }

    /// @inheritdoc ISafeguardPool
    function setSigner(address signer_) external override authenticate whenNotPaused {
        _setSigner(signer_);
    }

    function _setSigner(address signer_) internal {
        _srequire(signer_ != address(0), SwaapV2Errors.SIGNER_CANNOT_BE_NULL_ADDRESS);
        _signer = signer_;
        emit SignerChanged(signer_);
    }

    /// @inheritdoc ISafeguardPool
    function setPerfUpdateInterval(uint256 perfUpdateInterval) external override authenticate whenNotPaused {
        _setPerfUpdateInterval(perfUpdateInterval);
    }

    function _setPerfUpdateInterval(uint256 perfUpdateInterval) internal {

        _srequire(perfUpdateInterval >= _MIN_PERFORMANCE_UPDATE_INTERVAL, SwaapV2Errors.PERFORMANCE_UPDATE_INTERVAL_TOO_LOW);
        _srequire(perfUpdateInterval <= _MAX_PERFORMANCE_UPDATE_INTERVAL, SwaapV2Errors.PERFORMANCE_UPDATE_INTERVAL_TOO_HIGH);

        _packedPoolParams = _packedPoolParams.insertUint(
            perfUpdateInterval,
            _PERF_UPDATE_INTERVAL_BIT_OFFSET,
            _PERF_TIME_BIT_LENGTH
        );

        emit PerfUpdateIntervalChanged(perfUpdateInterval);
    }    
    
    /// @inheritdoc ISafeguardPool
    function setMaxPerfDev(uint256 maxPerfDev) external override authenticate whenNotPaused {
        _setMaxPerfDev(maxPerfDev);
    }

    /// @dev for gas optimization purposes we store (1 - max tolerance)
    function _setMaxPerfDev(uint256 maxPerfDev) internal {
        
        // the lower maxPerfDev value is, the less strict the performance check is (more permitted deviation)
        _srequire(maxPerfDev <= FixedPoint.ONE, SwaapV2Errors.MAX_PERFORMANCE_DEV_TOO_LOW);
        _srequire(maxPerfDev >= _MAX_PERFORMANCE_DEVIATION, SwaapV2Errors.MAX_PERFORMANCE_DEV_TOO_HIGH);
        
        _packedPoolParams = _packedPoolParams.insertUint(
            maxPerfDev,
            _MAX_PERF_DEV_BIT_OFFSET,
            _MAX_PERF_DEV_BIT_LENGTH
        );
        emit MaxPerfDevChanged(maxPerfDev);
    }

    /// @inheritdoc ISafeguardPool
    function setMaxTargetDev(uint256 maxTargetDev) external override authenticate whenNotPaused {
        _setMaxTargetDev(maxTargetDev);
    }
    
    /// @dev for gas optimization purposes we store (1 - max tolerance)
    function _setMaxTargetDev(uint256 maxTargetDev) internal {

        // the lower maxTargetDev value is, the less strict the balances check is (more permitted deviation)  
        _srequire(maxTargetDev <= FixedPoint.ONE, SwaapV2Errors.MAX_TARGET_DEV_TOO_LOW);
        _srequire(maxTargetDev >= _MAX_TARGET_DEVIATION, SwaapV2Errors.MAX_TARGET_DEV_TOO_LARGE);
        
        _packedPoolParams = _packedPoolParams.insertUint(
            maxTargetDev,
            _MAX_TARGET_DEV_BIT_OFFSET,
            _MAX_TARGET_DEV_BIT_LENGTH
        );
        emit MaxTargetDevChanged(maxTargetDev);
    }

    /// @inheritdoc ISafeguardPool
    function setMaxPriceDev(uint256 maxPriceDev) external override authenticate whenNotPaused {
        _setMaxPriceDev(maxPriceDev);
    }

    /// @dev for gas optimization purposes we store (1 - max tolerance)
    function _setMaxPriceDev(uint256 maxPriceDev) internal {

        // the lower maxPriceDev value is, the less strict the price check is (more permitted deviation)  
        _srequire(maxPriceDev <= FixedPoint.ONE, SwaapV2Errors.MAX_PRICE_DEV_TOO_LOW);
        _srequire(maxPriceDev >= _MAX_PRICE_DEVIATION, SwaapV2Errors.MAX_PRICE_DEV_TOO_LARGE);

        _packedPoolParams = _packedPoolParams.insertUint(
            maxPriceDev,
            _MAX_PRICE_DEV_BIT_OFFSET,
            _MAX_PRICE_DEV_BIT_LENGTH
        );
        emit MaxPriceDevChanged(maxPriceDev);
    }

    /**
     * @dev This function assumes that the pool is deployed with a modified version of the vault
     * that addresses a known reentrancy issue described here:
     * https://forum.balancer.fi/t/reentrancy-vulnerability-scope-expanded/4345.
     * The modified version of the vault is available here:
     * https://github.com/swaap-labs/swaap-v2-monorepo/commit/85e0ef66b460995129f196be42762186b3d3727d
     * If you're using an old version of the vault, you should add _ensureNotInVaultContext function
     * https://github.com/balancer/balancer-v2-monorepo/pull/2418/files
     * 
    */
    /// @inheritdoc ISafeguardPool
    function updatePerformance() external override nonReentrant whenNotPaused {

        bytes32 packedPoolParams = _packedPoolParams;

        (uint256 lastPerfUpdate, uint256 perfUpdateInterval) = _getPerformanceTimeParams(packedPoolParams);
        
        _srequire(block.timestamp > lastPerfUpdate + perfUpdateInterval, SwaapV2Errors.PERFORMANCE_UPDATE_TOO_SOON);

        (, uint256[] memory balances, ) = getVault().getPoolTokens(getPoolId());

        _upscaleArray(balances, _scalingFactors());

        uint256 amount0Per1 = _getOnChainAmountInPerOut(packedPoolParams, true);

        _updatePerformance(balances[0], balances[1], amount0Per1, totalSupply()); 
    }

    function _updatePerformance(
        uint256 balance0,
        uint256 balance1,
        uint256 amount0Per1,
        uint256 totalSupply
    ) private {
        
        uint256 currentTVLPerPT = (balance0.add(balance1.mulDown(amount0Per1))).divDown(totalSupply);
        
        (uint256 hodlBalancePerPT0, uint256 hodlBalancePerPT1) = getHodlBalancesPerPT();
        
        uint256 oldTVLPerPT = hodlBalancePerPT0.add(hodlBalancePerPT1.mulDown(amount0Per1));
        
        uint256 currentPerformance = currentTVLPerPT.divDown(oldTVLPerPT);

        hodlBalancePerPT0 = hodlBalancePerPT0.mulDown(currentPerformance);
        hodlBalancePerPT1 = hodlBalancePerPT1.mulDown(currentPerformance);

        _setHodlBalancesPerPT(hodlBalancePerPT0, hodlBalancePerPT1);

        emit PerformanceUpdated(hodlBalancePerPT0, hodlBalancePerPT1, currentPerformance, amount0Per1, block.timestamp);
    }

    function _setHodlBalancesPerPT(uint256 hodlBalancePerPT0, uint256 hodlBalancePerPT1) private {
        
        bytes32 hodlBalancesPerPT = WordCodec.encodeUint(
                hodlBalancePerPT0,
                _HODL_BALANCE_BIT_OFFSET_0,
                _HODL_BALANCE_BIT_LENGTH
        );
        
        hodlBalancesPerPT = hodlBalancesPerPT.insertUint(
                hodlBalancePerPT1,
                _HODL_BALANCE_BIT_OFFSET_1,
                _HODL_BALANCE_BIT_LENGTH
        );

        _hodlBalancesPerPT = hodlBalancesPerPT;

        _packedPoolParams = _packedPoolParams.insertUint(
            block.timestamp,
            _PERF_LAST_UPDATE_BIT_OFFSET,
            _PERF_TIME_BIT_LENGTH
        );
    }

    /// @inheritdoc ISafeguardPool
    function evaluateStablesPegStates() external override nonReentrant whenNotPaused {
        bytes32 packedPoolParams = _packedPoolParams;
        
        if(_isStable0 && _isFlexibleOracle0(packedPoolParams)) {
            bool newPegState = _canBePegged(_isTokenPegged0(packedPoolParams), _oracle0, _maxOracleTimeout0, _priceScaleFactor0);
            packedPoolParams = packedPoolParams.insertBool(newPegState, _TOKEN_0_PEGGED_BIT_OFFSET);
        }
        
        if(_isStable1 && _isFlexibleOracle1(packedPoolParams)) {
            bool newPegState = _canBePegged(_isTokenPegged1(packedPoolParams), _oracle1, _maxOracleTimeout1, _priceScaleFactor1);
            packedPoolParams = packedPoolParams.insertBool(newPegState, _TOKEN_1_PEGGED_BIT_OFFSET);
        }

        _packedPoolParams = packedPoolParams;
        emit PegStatesUpdated(_isTokenPegged0(packedPoolParams), _isTokenPegged1(packedPoolParams));
    }

    /**
    * Getters
    */

    /// @inheritdoc ISafeguardPool
    function getPoolPerformance() external view override returns(uint256 performance){
        (, uint256[] memory balances, ) = getVault().getPoolTokens(getPoolId());

        _upscaleArray(balances, _scalingFactors());

        uint256 onChainAmountInPerOut = _getOnChainAmountInPerOut(_packedPoolParams, true);

        performance = _getPerf(true, balances[0], balances[1], onChainAmountInPerOut, totalSupply());
    }

    function _getPerf(
        bool    isTokenInToken0,
        uint256 newBalanceIn,
        uint256 newBalanceOut,
        uint256 onChainAmountInPerOut,
        uint256 totalSupply
    ) internal view returns (uint256) {
        
        (uint256 newBalancePerPTIn, uint256 newBalancePerPTOut, uint256 hodlBalancePerPTIn, uint256 hodlBalancePerPTOut) = 
            _getBalancesPerPT(isTokenInToken0, newBalanceIn, newBalanceOut, totalSupply);
        
        return _getPerfFromBalancesPerPT(
            newBalancePerPTIn,
            newBalancePerPTOut,
            hodlBalancePerPTIn,
            hodlBalancePerPTOut,
            onChainAmountInPerOut
        );
    }

    function _getPerfFromBalancesPerPT(
        uint256 newBalancePerPTIn,
        uint256 newBalancePerPTOut,
        uint256 hodlBalancePerPTIn,
        uint256 hodlBalancePerPTOut,
        uint256 onChainAmountInPerOut
    ) internal pure returns (uint256) {

        uint256 newTVLPerPT = (newBalancePerPTIn.divDown(onChainAmountInPerOut)).add(newBalancePerPTOut);
        uint256 oldTVLPerPT = (hodlBalancePerPTIn.divDown(onChainAmountInPerOut)).add(hodlBalancePerPTOut);

        return newTVLPerPT.divDown(oldTVLPerPT);
    }

    function _getBalancesPerPT(
        bool    isTokenInToken0,
        uint256 newBalanceIn,
        uint256 newBalanceOut,
        uint256 totalSupply
    ) internal view returns (uint256, uint256, uint256, uint256) {

        (uint256 hodlBalancePerPT0, uint256 hodlBalancePerPT1) = getHodlBalancesPerPT();

        (uint256 hodlBalancePerPTIn, uint256 hodlBalancePerPTOut) = isTokenInToken0?
            (hodlBalancePerPT0, hodlBalancePerPT1) :
            (hodlBalancePerPT1, hodlBalancePerPT0); 

        uint256 newBalancePerPTIn = newBalanceIn.divDown(totalSupply);
        uint256 newBalancePerPTOut = newBalanceOut.divDown(totalSupply);

        return(newBalancePerPTIn, newBalancePerPTOut, hodlBalancePerPTIn, hodlBalancePerPTOut);
    }

    function _isTokenPegged0(bytes32 packedPoolParams) internal pure returns(bool){
        return packedPoolParams.decodeBool(_TOKEN_0_PEGGED_BIT_OFFSET);
    }

    function _isTokenPegged1(bytes32 packedPoolParams) internal pure returns(bool){
        return packedPoolParams.decodeBool(_TOKEN_1_PEGGED_BIT_OFFSET);
    }

    /// @inheritdoc ISafeguardPool
    function isAllowlistEnabled() public view override returns(bool) {
        return _mustAllowlistLPs;
    }

    /// @inheritdoc ISafeguardPool
    function getHodlBalancesPerPT() public view override returns(uint256 hodlBalancePerPT0, uint256 hodlBalancePerPT1) {
        
        bytes32 hodlBalancesPerPT = _hodlBalancesPerPT;
    
        hodlBalancePerPT0 = hodlBalancesPerPT.decodeUint(
                _HODL_BALANCE_BIT_OFFSET_0,
                _HODL_BALANCE_BIT_LENGTH
        );
        
        hodlBalancePerPT1 = hodlBalancesPerPT.decodeUint(
                _HODL_BALANCE_BIT_OFFSET_1,
                _HODL_BALANCE_BIT_LENGTH
        );
    
    }

    /// @inheritdoc ISafeguardPool
    function getOnChainAmountInPerOut(address tokenIn) external view override returns(uint256) {
        return _getOnChainAmountInPerOut(_packedPoolParams, IERC20(tokenIn) == _token0);
    }

    /**
    * @notice returns the relative price such as: amountIn = relativePrice * amountOut
    */
    function _getOnChainAmountInPerOut(bytes32 packedPoolParams, bool isTokenInToken0)
    internal view returns(uint256) {
        
        uint256 price0;
        
        if(_isStable0 && _isFlexibleOracle0(packedPoolParams) && _isTokenPegged0(packedPoolParams)) {
            price0 = FixedPoint.ONE;
        } else {
            price0 = _getPriceFromOracle(_oracle0, _maxOracleTimeout0, _priceScaleFactor0);
        }

        uint256 price1;
        
        if(_isStable1 && _isFlexibleOracle1(packedPoolParams) && _isTokenPegged1(packedPoolParams)) {
            price1 = FixedPoint.ONE;
        } else {
            price1 = _getPriceFromOracle(_oracle1, _maxOracleTimeout1, _priceScaleFactor1);
        }
       
        return isTokenInToken0? price1.divDown(price0) : price0.divDown(price1); 
    }

    function _getPriceFromOracle(
        AggregatorV3Interface oracle,
        uint256 maxTimeout,
        uint256 priceScaleFactor
    ) internal view returns(uint256){
        return  _upscale(ChainlinkUtils.getLatestPrice(oracle, maxTimeout), priceScaleFactor);
    }

    /// @inheritdoc ISafeguardPool
    function getPoolParameters() external view override
    returns (
        uint256 maxPerfDev,
        uint256 maxTargetDev,
        uint256 maxPriceDev,
        uint256 lastPerfUpdate,
        uint256 perfUpdateInterval
    ) {

        bytes32 packedPoolParams = _packedPoolParams;
        
        maxPerfDev = _getMaxPerfDev(packedPoolParams);

        maxTargetDev = _getMaxTargetDev(packedPoolParams);
        
        maxPriceDev = _getMaxPriceDev(packedPoolParams);
        
        (lastPerfUpdate, perfUpdateInterval) = _getPerformanceTimeParams(packedPoolParams);

    }

    function _isFlexibleOracle0(bytes32 packedPoolParams) internal pure returns(bool) {
        return packedPoolParams.decodeBool(_FLEXIBLE_ORACLE_0_BIT_OFFSET);
    }
    
    function _isFlexibleOracle1(bytes32 packedPoolParams) internal pure returns(bool) {
        return packedPoolParams.decodeBool(_FLEXIBLE_ORACLE_1_BIT_OFFSET);
    }

    function _getMaxPerfDev(bytes32 packedPoolParams) internal pure returns (uint256 maxPerfDev) {
        maxPerfDev = packedPoolParams.decodeUint(_MAX_PERF_DEV_BIT_OFFSET, _MAX_PERF_DEV_BIT_LENGTH);
    }

    function _getMaxTargetDev(bytes32 packedPoolParams) internal pure returns (uint256 maxTargetDev) {
        maxTargetDev = packedPoolParams.decodeUint(_MAX_TARGET_DEV_BIT_OFFSET, _MAX_TARGET_DEV_BIT_LENGTH);
    }

    function _getMaxPriceDev(bytes32 packedPoolParams) internal pure returns (uint256 maxPriceDev) {
        maxPriceDev = packedPoolParams.decodeUint(_MAX_PRICE_DEV_BIT_OFFSET, _MAX_PRICE_DEV_BIT_LENGTH);
    }

    function _getPerformanceTimeParams(bytes32 packedPoolParams) internal pure
    returns(uint256 lastPerfUpdate, uint256 perfUpdateInterval) {
        
        lastPerfUpdate = packedPoolParams.decodeUint(_PERF_LAST_UPDATE_BIT_OFFSET, _PERF_TIME_BIT_LENGTH);

        perfUpdateInterval = packedPoolParams.decodeUint(_PERF_UPDATE_INTERVAL_BIT_OFFSET, _PERF_TIME_BIT_LENGTH);
    }

    /// @inheritdoc ISafeguardPool
    function getOracleParams() external view override returns(OracleParams[] memory) {
        OracleParams[] memory oracleParams = new OracleParams[](2);
        bytes32 packedPoolParams = _packedPoolParams;

        oracleParams[0] = OracleParams({
            oracle: _oracle0,
            maxTimeout: _maxOracleTimeout0,
            isStable: _isStable0,
            isFlexibleOracle: _isFlexibleOracle0(packedPoolParams),
            isPegged: _isTokenPegged0(packedPoolParams),
            priceScalingFactor: _priceScaleFactor0
        });

        oracleParams[1] = OracleParams({
            oracle: _oracle1,
            maxTimeout: _maxOracleTimeout1,
            isStable: _isStable1,
            isFlexibleOracle: _isFlexibleOracle1(packedPoolParams),
            isPegged: _isTokenPegged1(packedPoolParams),
            priceScalingFactor: _priceScaleFactor1
        });

        return oracleParams;
    }

    function _canBePegged(
        bool isTokenPegged,
        AggregatorV3Interface oracle,
        uint256 maxOracleTimeout,
        uint256 priceScaleFactor
    ) internal view returns(bool) {

        uint256 currentPrice = _getPriceFromOracle(oracle, maxOracleTimeout, priceScaleFactor);
        
        (uint256 priceMin, uint256 priceMax) = currentPrice < FixedPoint.ONE?
            (currentPrice, FixedPoint.ONE) : (FixedPoint.ONE, currentPrice);

        uint256 relativePriceDifference = (priceMax - priceMin);

        if(!isTokenPegged && relativePriceDifference <= _REPEG_PRICE_BOUND) {
            return true; // token should gain back peg 
        } else if (isTokenPegged && relativePriceDifference >= _UNPEG_PRICE_BOUND) {
            return false; // token should be unpegged
        }

        return isTokenPegged;
    }

    /// @inheritdoc ISignatureSafeguard
    function signer() public view override(ISignatureSafeguard, SignatureSafeguard) returns(address){
        return _signer;
    }

    function _getTotalTokens() internal pure override returns (uint256) {
        return _NUM_TOKENS;
    }

    function _getMaxTokens() internal pure override returns (uint256) {
        return _NUM_TOKENS;
    }

    function _scalingFactors() internal view override returns (uint256[] memory) {
        uint256[] memory scalingFactors = new uint256[](_NUM_TOKENS);
        scalingFactors[0] = _scaleFactor0;
        scalingFactors[1] = _scaleFactor1;
        return scalingFactors;
    }

    function _scalingFactor(IERC20 token) internal view override returns (uint256) {
        if (token == _token0) {
            return _scaleFactor0;
        }
        return _scaleFactor1;
    }

    function _scalingFactorsInAndOut(bool isToken0) internal view returns (uint256, uint256) {
        if (isToken0) {
            return (_scaleFactor0, _scaleFactor1);
        }
        return (_scaleFactor1, _scaleFactor0);
    }

    /**
    * @dev Safeguard pool does not support on-chain swap fees. They should be included in the pricing
    * of the signed quotes. The following functions are overriden to reduce contract size and disable
    * on-chain swap fees.
    */

    // Safeguard pool does not support on-chain swap fees.
    function _setSwapFeePercentage(uint256) internal pure override {
        return;
    }

    // Safeguard pool does not support on-chain swap fees.
    function getSwapFeePercentage() public pure override(BasePool, IBasePool) returns (uint256) {
        return 0;
    }

    // Safeguard pool does not support on-chain swap fees.
    function _getMinSwapFeePercentage() internal override pure returns (uint256) {
        return 0;
    }

    // Safeguard pool does not support on-chain swap fees.
    function _getMaxSwapFeePercentage() internal override pure returns (uint256) {
        return 0;
    }

    /*
    * Management fees
    */

   function _onDisableRecoveryMode() internal override {
        // resets last claim time to the current time in order to prevent claiming fees accrued
        // when the pool was in recovery mode
        _previousClaimTime = uint32(block.timestamp);
    }

    function _beforeJoinExit() private {
        _claimManagementFees();
    }

    /// @inheritdoc ISafeguardPool
    function claimManagementFees() external override whenNotPaused {
        _claimManagementFees();
    }

    function _claimManagementFees() internal {

        uint256 currentTime = block.timestamp;
        uint256 elapsedTime = currentTime.sub(uint256(_previousClaimTime));
        
        if(elapsedTime > 0) {
            // update last claim time
            _previousClaimTime = uint32(currentTime);
            uint256 yearlyRate = uint256(_yearlyRate);
            uint256 previousTotalSupply = totalSupply();

            if(yearlyRate > 0) {
                // returns bpt that needs to be minted
                uint256 protocolFees = SafeguardMath.calcAccumulatedManagementFees(
                    elapsedTime,
                    yearlyRate,
                    previousTotalSupply
                );
                
                _payProtocolFees(protocolFees);
                emit ManagementFeesClaimed(protocolFees, previousTotalSupply, yearlyRate, currentTime);
            }
        }

    }

    /// @inheritdoc ISafeguardPool
    function setManagementFees(uint256 yearlyFees) external override authenticate whenNotPaused {
        _setManagementFees(yearlyFees);
    }

    function _setManagementFees(uint256 yearlyFees) private {               
        // claim previous manag
        _claimManagementFees();
        
        _setYearlyRate(yearlyFees);
    }

    function _setYearlyRate(uint256 yearlyFees) private {
        _srequire(yearlyFees <= _MAX_YEARLY_FEES, SwaapV2Errors.FEES_TOO_HIGH);
        _yearlyFees = uint64(yearlyFees);
        _yearlyRate = uint32(SafeguardMath.calcYearlyRate(yearlyFees));
        emit ManagementFeesUpdated(yearlyFees);
    }

    /// @inheritdoc ISafeguardPool
    function getManagementFeesParams() public view override returns(uint256, uint256, uint256) {
        return (_yearlyFees, _yearlyRate, _previousClaimTime);
    }
}