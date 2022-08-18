// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;  
pragma abicoder v2;

import "BalancerFixedPoint.sol";
import "BalancerStableMath.sol";

struct ExactInQueryParam{
    address tokenIn;
    address tokenOut;
    uint256 balanceIn;
    uint256 weightIn;
    uint256 balanceOut;
    uint256 weightOut;
    uint256 amountIn;
    uint256 swapFeePercentage;
}

struct ExactInStableQueryParam{
    address[] tokens;
    uint256[] balances;
    uint256 currentAmp;
    uint256 tokenIndexIn;
    uint256 tokenIndexOut;
    uint256 amountIn;
    uint256 swapFeePercentage;
}

interface IERC20Metadata {
    function decimals() external view returns (uint8);
}

/// @dev Swap Simulator for Balancer V2
contract BalancerSwapSimulator {    
    uint256 internal constant _MAX_IN_RATIO = 0.3e18;
	
    /// @dev reference https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/pkg/pool-weighted/contracts/WeightedMath.sol#L78
    function calcOutGivenIn(ExactInQueryParam memory _query) public view returns (uint256) {	
        /**********************************************************************************************
        // outGivenIn                                                                                //
        // aO = amountOut                                                                            //
        // bO = balanceOut                                                                           //
        // bI = balanceIn              /      /            bI             \    (wI / wO) \           //
        // aI = amountIn    aO = bO * |  1 - | --------------------------  | ^            |          //
        // wI = weightIn               \      \       ( bI + aI )         /              /           //
        // wO = weightOut                                                                            //
        **********************************************************************************************/
        
        // upscale all balances and amounts
        _query.amountIn = _subtractSwapFeeAmount(_query.amountIn, _query.swapFeePercentage);
        
        uint256 _scalingFactorIn = _computeScalingFactorWeightedPool(_query.tokenIn);
        _query.amountIn = BalancerMath.mul(_query.amountIn, _scalingFactorIn);
        _query.balanceIn = BalancerMath.mul(_query.balanceIn, _scalingFactorIn);
        require(_query.balanceIn > _query.amountIn, "!amtIn");
		
        uint256 _scalingFactorOut = _computeScalingFactorWeightedPool(_query.tokenOut);
        _query.balanceOut = BalancerMath.mul(_query.balanceOut, _scalingFactorOut);
		
        require(_query.amountIn <= BalancerFixedPoint.mulDown(_query.balanceIn, _MAX_IN_RATIO), "!maxIn");
		
        uint256 denominator = BalancerFixedPoint.add(_query.balanceIn, _query.amountIn);
        uint256 base = BalancerFixedPoint.divUp(_query.balanceIn, denominator);
        uint256 exponent = BalancerFixedPoint.divDown(_query.weightIn, _query.weightOut);
        uint256 power = BalancerFixedPoint.powUp(base, exponent);

        uint256 _scaledOut = BalancerFixedPoint.mulDown(_query.balanceOut, BalancerFixedPoint.complement(power));
        return BalancerMath.divDown(_scaledOut, _scalingFactorOut);
    }	
	
    /// @dev reference https://etherscan.io/address/0x7b50775383d3d6f0215a8f290f2c9e2eebbeceb2#code#F1#L244
    function calcOutGivenInForStable(ExactInStableQueryParam memory _query) public view returns (uint256) {
        /**************************************************************************************************************
        // outGivenIn token x for y - polynomial equation to solve                                                   //
        // ay = amount out to calculate                                                                              //
        // by = balance token out                                                                                    //
        // y = by - ay (finalBalanceOut)                                                                             //
        // D = invariant                                               D                     D^(n+1)                 //
        // A = amplification coefficient               y^2 + ( S - ----------  - D) * y -  ------------- = 0         //
        // n = number of tokens                                    (A * n^n)               A * n^2n * P              //
        // S = sum of final balances but y                                                                           //
        // P = product of final balances but y                                                                       //
        **************************************************************************************************************/
		
        // upscale all balances and amounts
        uint256 _tkLen = _query.tokens.length;
        uint256[] memory _scalingFactors = new uint256[](_tkLen);
        for (uint256 i = 0;i < _tkLen;++i){
             _scalingFactors[i] = _computeScalingFactor(_query.tokens[i]);
        }
		
        _query.amountIn = _subtractSwapFeeAmount(_query.amountIn, _query.swapFeePercentage);
        _query.balances = _upscaleStableArray(_query.balances, _scalingFactors);
        _query.amountIn = _upscaleStable(_query.amountIn, _scalingFactors[_query.tokenIndexIn]);
		
        uint256 invariant = BalancerStableMath._calculateInvariant(_query.currentAmp, _query.balances, true);
			
        _query.balances[_query.tokenIndexIn] = BalancerFixedPoint.add(_query.balances[_query.tokenIndexIn], _query.amountIn);
        uint256 finalBalanceOut = BalancerStableMath._getTokenBalanceGivenInvariantAndAllOtherBalances(_query.currentAmp, _query.balances, invariant, _query.tokenIndexOut);

        uint256 _scaledOut = BalancerFixedPoint.sub(_query.balances[_query.tokenIndexOut], BalancerFixedPoint.add(finalBalanceOut, 1));	
        return _downscaleStable(_scaledOut, _scalingFactors[_query.tokenIndexOut]);
    }	
	
    /// @dev scaling factors for weighted pool: reference https://etherscan.io/address/0xc45d42f801105e861e86658648e3678ad7aa70f9#code#F24#L474
    function _computeScalingFactorWeightedPool(address token) private view returns (uint256) {
        return 10**BalancerFixedPoint.sub(18, IERC20Metadata(token).decimals());
    }
	
    /// @dev scaling factors for stable pool: reference https://etherscan.io/address/0x06df3b2bbb68adc8b0e302443692037ed9f91b42#code#F12#L510
    function _computeScalingFactor(address token) internal view returns (uint256) {
        return BalancerFixedPoint.ONE * 10**BalancerFixedPoint.sub(18, IERC20Metadata(token).decimals());
    }
	
    function _upscaleStableArray(uint256[] memory amounts, uint256[] memory scalingFactors) internal pure returns (uint256[] memory) {
        uint256 _len = amounts.length;
        for (uint256 i = 0; i < _len;++i) {
             amounts[i] = _upscaleStable(amounts[i], scalingFactors[i]);
        }
        return amounts;
    }
	
    function _upscaleStable(uint256 amount, uint256 scalingFactor) internal pure returns (uint256) {
        return BalancerFixedPoint.mulDown(amount, scalingFactor);
    }
	
    function _downscaleStable(uint256 amount, uint256 scalingFactor) internal pure returns (uint256) {
        return BalancerFixedPoint.divDown(amount, scalingFactor);
    }
	
    function _subtractSwapFeeAmount(uint256 amount, uint256 _swapFeePercentage) public view returns (uint256) {
        uint256 feeAmount = BalancerFixedPoint.mulUp(amount, _swapFeePercentage);
        return BalancerFixedPoint.sub(amount, feeAmount);
    }

}