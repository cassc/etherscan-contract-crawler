pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/AMO__IBalancerVault.sol";
import "../helpers/AMOCommon.sol";


interface IWeightPool2Tokens {
    function getNormalizedWeights() external view returns (uint256[] memory);
}

contract PoolHelper {
    using SafeERC20 for IERC20;

    AMO__IBalancerVault public immutable balancerVault;
    IERC20 public immutable bptToken;
    IERC20 public immutable temple;
    IERC20 public immutable stable;
    address public immutable amo;
    // @notice Temple price floor denominator
    uint256 public constant TPF_PRECISION = 10_000;

    // @notice temple index in balancer pool
    uint64 public immutable templeIndexInBalancerPool;

    bytes32 public immutable balancerPoolId;

    constructor(
      address _balancerVault,
      address _temple,
      address _stable,
      address _bptToken,
      address _amo,
      uint64 _templeIndexInPool,
      bytes32 _balancerPoolId
    ) {
      balancerPoolId = _balancerPoolId;
      balancerVault = AMO__IBalancerVault(_balancerVault);
      temple = IERC20(_temple);
      stable = IERC20(_stable);
      bptToken = IERC20(_bptToken);
      amo = _amo;
      templeIndexInBalancerPool = _templeIndexInPool;
    }

    function getBalances() public view returns (uint256[] memory balances) {
      (, balances,) = balancerVault.getPoolTokens(balancerPoolId);
    }

    function getTempleStableBalances() public view returns (uint256 templeBalance, uint256 stableBalance) {
      uint256[] memory balances = getBalances();
      (templeBalance, stableBalance) = (templeIndexInBalancerPool == 0) 
        ? (balances[0], balances[1]) 
        : (balances[1], balances[0]);
    }

    function getSpotPriceScaled() public view returns (uint256 spotPriceScaled) {
        (uint256 templeBalance, uint256 stableBalance) = getTempleStableBalances();
        spotPriceScaled = (TPF_PRECISION * stableBalance) / templeBalance;
    }

    function isSpotPriceBelowTPF(uint256 templePriceFloorNumerator) external view returns (bool) {
        return getSpotPriceScaled() < templePriceFloorNumerator;
    }

    // below TPF by a given slippage percentage
    function isSpotPriceBelowTPF(uint256 slippage, uint256 templePriceFloorNumerator) public view returns (bool) {
        uint256 slippageTPF = (slippage * templePriceFloorNumerator) / TPF_PRECISION;
        return getSpotPriceScaled() < (templePriceFloorNumerator - slippageTPF);
    }

    function isSpotPriceBelowTPFLowerBound(uint256 rebalancePercentageBoundLow, uint256 templePriceFloorNumerator) public view returns (bool) {
        return isSpotPriceBelowTPF(rebalancePercentageBoundLow, templePriceFloorNumerator);
    }

    function isSpotPriceAboveTPFUpperBound(uint256 rebalancePercentageBoundUp, uint256 templePriceFloorNumerator) public view returns (bool) {
        return isSpotPriceAboveTPF(rebalancePercentageBoundUp, templePriceFloorNumerator);
    }

    // slippage in bps
    // above TPF by a given slippage percentage
    function isSpotPriceAboveTPF(uint256 slippage, uint256 templePriceFloorNumerator) public view returns (bool) {
      uint256 slippageTPF = (slippage * templePriceFloorNumerator) / TPF_PRECISION;
      return getSpotPriceScaled() > (templePriceFloorNumerator + slippageTPF);
    }

    function isSpotPriceAboveTPF(uint256 templePriceFloorNumerator) external view returns (bool) {
        return getSpotPriceScaled() > templePriceFloorNumerator;
    }

    // @notice will exit take price above tpf by a percentage
    // percentage in bps
    // tokensOut: expected min amounts out. for rebalance this is expected Temple tokens out
    function willExitTakePriceAboveTPFUpperBound(
        uint256 tokensOut,
        uint256 rebalancePercentageBoundUp,
        uint256 templePriceFloorNumerator
    ) public view returns (bool) {
        uint256 percentageIncrease = (templePriceFloorNumerator * rebalancePercentageBoundUp) / TPF_PRECISION;
        uint256 maxNewTpf = percentageIncrease + templePriceFloorNumerator;
        (uint256 templeBalance, uint256 stableBalance) = getTempleStableBalances();

        // a ratio of stable balances aginst temple balances
        uint256 newTempleBalance = templeBalance - tokensOut;
        uint256 spot = (stableBalance * TPF_PRECISION ) / newTempleBalance;
        return spot > maxNewTpf;
    }

    function willStableJoinTakePriceAboveTPFUpperBound(
        uint256 tokensIn,
        uint256 rebalancePercentageBoundUp,
        uint256 templePriceFloorNumerator
    ) public view returns (bool) {
        uint256 percentageIncrease = (templePriceFloorNumerator * rebalancePercentageBoundUp) / TPF_PRECISION;
        uint256 maxNewTpf = percentageIncrease + templePriceFloorNumerator;
        (uint256 templeBalance, uint256 stableBalance) = getTempleStableBalances();

        uint256 newStableBalance = stableBalance + tokensIn;
        uint256 spot = (newStableBalance * TPF_PRECISION ) / templeBalance;
        return spot > maxNewTpf;
    }

    function willStableExitTakePriceBelowTPFLowerBound(
        uint256 tokensOut,
        uint256 rebalancePercentageBoundLow,
        uint256 templePriceFloorNumerator
    ) public view returns (bool) {
        uint256 percentageDecrease = (templePriceFloorNumerator * rebalancePercentageBoundLow) / TPF_PRECISION;
        uint256 minNewTpf = templePriceFloorNumerator - percentageDecrease;
        (uint256 templeBalance, uint256 stableBalance) = getTempleStableBalances();

        uint256 newStableBalance = stableBalance - tokensOut;
        uint256 spot = (newStableBalance * TPF_PRECISION) / templeBalance;
        return spot < minNewTpf;
    }

    function willJoinTakePriceBelowTPFLowerBound(
        uint256 tokensIn,
        uint256 rebalancePercentageBoundLow,
        uint256 templePriceFloorNumerator
    ) public view returns (bool) {
        uint256 percentageDecrease = (templePriceFloorNumerator * rebalancePercentageBoundLow) / TPF_PRECISION;
        uint256 minNewTpf = templePriceFloorNumerator - percentageDecrease;
        (uint256 templeBalance, uint256 stableBalance) = getTempleStableBalances();

        // a ratio of stable balances against temple balances
        uint256 newTempleBalance = templeBalance + tokensIn;
        uint256 spot = (stableBalance * TPF_PRECISION) / newTempleBalance;
        return spot < minNewTpf;
    }

    // get slippage between spot price before and spot price now
    function getSlippage(uint256 spotPriceBeforeScaled) public view returns (uint256) {
        uint256 spotPriceNowScaled = getSpotPriceScaled();
        // taking into account both rebalance up or down
        uint256 slippageDifference;
        unchecked {
            slippageDifference = (spotPriceNowScaled > spotPriceBeforeScaled)
                ? spotPriceNowScaled - spotPriceBeforeScaled
                : spotPriceBeforeScaled - spotPriceNowScaled;
        }
        return (slippageDifference * TPF_PRECISION) / spotPriceBeforeScaled;
    }

    function createPoolExitRequest(
        uint256 bptAmountIn,
        uint256 minAmountOut,
        uint256 exitTokenIndex
    ) internal view returns (AMO__IBalancerVault.ExitPoolRequest memory request) {
        address[] memory assets = new address[](2);
        uint256[] memory minAmountsOut = new uint256[](2);

        (assets[0], assets[1]) = templeIndexInBalancerPool == 0 ? (address(temple), address(stable)) : (address(stable), address(temple));
        (minAmountsOut[0], minAmountsOut[1]) = exitTokenIndex == uint256(0) ? (minAmountOut, uint256(0)) : (uint256(0), minAmountOut); 
        // EXACT_BPT_IN_FOR_ONE_TOKEN_OUT index is 0 for exitKind
        bytes memory encodedUserdata = abi.encode(uint256(0), bptAmountIn, exitTokenIndex);
        request.assets = assets;
        request.minAmountsOut = minAmountsOut;
        request.userData = encodedUserdata;
        request.toInternalBalance = false;
    }

    function createPoolJoinRequest(
        uint256 amountIn,
        uint256 tokenIndex,
        uint256 minTokenOut
    ) internal view returns (AMO__IBalancerVault.JoinPoolRequest memory request) {
        IERC20[] memory assets = new IERC20[](2);
        uint256[] memory maxAmountsIn = new uint256[](2);
    
        (assets[0], assets[1]) = templeIndexInBalancerPool == 0 ? (temple, stable) : (stable, temple);
        (maxAmountsIn[0], maxAmountsIn[1]) = tokenIndex == uint256(0) ? (amountIn, uint256(0)) : (uint256(0), amountIn);
        //uint256 joinKind = 1; //EXACT_TOKENS_IN_FOR_BPT_OUT
        bytes memory encodedUserdata = abi.encode(uint256(1), maxAmountsIn, minTokenOut);
        request.assets = assets;
        request.maxAmountsIn = maxAmountsIn;
        request.userData = encodedUserdata;
        request.fromInternalBalance = false;
    }

    function exitPool(
        uint256 bptAmountIn,
        uint256 minAmountOut,
        uint256 rebalancePercentageBoundLow,
        uint256 rebalancePercentageBoundUp,
        uint256 postRebalanceSlippage,
        uint256 exitTokenIndex,
        uint256 templePriceFloorNumerator,
        IERC20 exitPoolToken
    ) external onlyAmo returns (uint256 amountOut) {
        exitPoolToken == temple ? 
            validateTempleExit(minAmountOut, rebalancePercentageBoundUp, rebalancePercentageBoundLow, templePriceFloorNumerator) :
            validateStableExit(minAmountOut, rebalancePercentageBoundUp, rebalancePercentageBoundLow, templePriceFloorNumerator);

        // create request
        AMO__IBalancerVault.ExitPoolRequest memory exitPoolRequest = createPoolExitRequest(bptAmountIn,
            minAmountOut, exitTokenIndex);

        // execute call and check for sanity
        uint256 exitTokenBalanceBefore = exitPoolToken.balanceOf(msg.sender);
        uint256 spotPriceScaledBefore = getSpotPriceScaled();
        balancerVault.exitPool(balancerPoolId, address(this), msg.sender, exitPoolRequest);
        uint256 exitTokenBalanceAfter = exitPoolToken.balanceOf(msg.sender);

        unchecked {
            amountOut = exitTokenBalanceAfter - exitTokenBalanceBefore;
        }

        if (uint64(getSlippage(spotPriceScaledBefore)) > postRebalanceSlippage) {
            revert AMOCommon.HighSlippage();
        }
    }

    function joinPool(
        uint256 amountIn,
        uint256 minBptOut,
        uint256 rebalancePercentageBoundUp,
        uint256 rebalancePercentageBoundLow,
        uint256 templePriceFloorNumerator,
        uint256 postRebalanceSlippage,
        uint256 joinTokenIndex,
        IERC20 joinPoolToken
    ) external onlyAmo returns (uint256 bptOut) {
        joinPoolToken == temple ? 
            validateTempleJoin(amountIn, rebalancePercentageBoundUp, rebalancePercentageBoundLow, templePriceFloorNumerator) :
            validateStableJoin(amountIn, rebalancePercentageBoundUp, rebalancePercentageBoundLow, templePriceFloorNumerator);

        // create request
        AMO__IBalancerVault.JoinPoolRequest memory joinPoolRequest = createPoolJoinRequest(amountIn, joinTokenIndex, minBptOut);

        // approve
        if (joinPoolToken == temple) {
            joinPoolToken.safeIncreaseAllowance(address(balancerVault), amountIn);
        }

        // execute and sanity check
        uint256 bptAmountBefore = bptToken.balanceOf(msg.sender);
        uint256 spotPriceScaledBefore = getSpotPriceScaled();
        balancerVault.joinPool(balancerPoolId, address(this), msg.sender, joinPoolRequest);
        uint256 bptAmountAfter = bptToken.balanceOf(msg.sender);

        unchecked {
            bptOut = bptAmountAfter - bptAmountBefore;
        }

        // revert if high slippage after pool join
        if (uint64(getSlippage(spotPriceScaledBefore)) > postRebalanceSlippage) {
            revert AMOCommon.HighSlippage();
        }
    }

    function validateTempleJoin(
        uint256 amountIn,
        uint256 rebalancePercentageBoundUp,
        uint256 rebalancePercentageBoundLow,
        uint256 templePriceFloorNumerator
    ) internal view {
        if (!isSpotPriceAboveTPFUpperBound(rebalancePercentageBoundUp, templePriceFloorNumerator)) {
            revert AMOCommon.NoRebalanceDown();
        }
        // should rarely be the case, but a sanity check nonetheless
        if (willJoinTakePriceBelowTPFLowerBound(amountIn, rebalancePercentageBoundLow, templePriceFloorNumerator)) {
            revert AMOCommon.HighSlippage();
        }
    }

    function validateTempleExit(
        uint256 amountOut,
        uint256 rebalancePercentageBoundUp,
        uint256 rebalancePercentageBoundLow,
        uint256 templePriceFloorNumerator
    ) internal view {
        // check spot price is below TPF by lower bound
        if (!isSpotPriceBelowTPFLowerBound(rebalancePercentageBoundLow, templePriceFloorNumerator)) {
            revert AMOCommon.NoRebalanceUp();
        }

        // will exit take price above tpf + upper bound
        // should rarely be the case, but a sanity check nonetheless
        if (willExitTakePriceAboveTPFUpperBound(amountOut, rebalancePercentageBoundUp, templePriceFloorNumerator)) {
            revert AMOCommon.HighSlippage();
        }
    }

    function validateStableJoin(
        uint256 amountIn,
        uint256 rebalancePercentageBoundUp,
        uint256 rebalancePercentageBoundLow,
        uint256 templePriceFloorNumerator
    ) internal view {
        if (!isSpotPriceBelowTPFLowerBound(rebalancePercentageBoundLow, templePriceFloorNumerator)) {
            revert AMOCommon.NoRebalanceUp();
        }
        // should rarely be the case, but a sanity check nonetheless
        if (willStableJoinTakePriceAboveTPFUpperBound(amountIn, rebalancePercentageBoundUp, templePriceFloorNumerator)) {
            revert AMOCommon.HighSlippage();
        }
    }

    function validateStableExit(
        uint256 amountOut,
        uint256 rebalancePercentageBoundUp,
        uint256 rebalancePercentageBoundLow,
        uint256 templePriceFloorNumerator
    ) internal view {
        if (!isSpotPriceAboveTPFUpperBound(rebalancePercentageBoundUp, templePriceFloorNumerator)) {
            revert AMOCommon.NoRebalanceDown();
        }
        // should rarely be the case, but a sanity check nonetheless
        if (willStableExitTakePriceBelowTPFLowerBound(amountOut, rebalancePercentageBoundLow, templePriceFloorNumerator)) {
            revert AMOCommon.HighSlippage();
        }
    }

    modifier onlyAmo() {
        if (msg.sender != amo) {
            revert AMOCommon.OnlyAMO();
        }
        _;
    }
}