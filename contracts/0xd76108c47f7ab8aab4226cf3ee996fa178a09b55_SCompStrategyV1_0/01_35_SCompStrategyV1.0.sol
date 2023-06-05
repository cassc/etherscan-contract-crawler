// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./SCompStrategyBase.sol";

/*
Version 1.0:
    - Amount out min calculate with previous balance check
*/
contract SCompStrategyV1_0 is
SCompStrategyBase
{
    using SafeMath for uint256;

    uint256 public variantPrice = 300; // 5000 -> 50% ; 500 -> 5% ; 50 -> 0.5% ; 5 -> 0.05%

    /**
     * @param _nameStrategy name string of strategy
     * @param _governance is authorized actors, authorized pauser, can call earn, can set params strategy, receive fee harvest
     * @param _strategist receive fee compound
     * @param _want address lp to deposit
     * @param _tokenCompound address token to compound
     * @param _pid id of pool in convex booster
     * @param _feeConfig performanceFee governance e strategist + fee withdraw
     * @param _curvePool curve pool config
     */
    constructor(
        string memory _nameStrategy,
        address _governance,
        address _strategist,
        address _controller,
        address _want,
        address _tokenCompound,
        uint256 _pid,
        uint256[3] memory _feeConfig,
        CurvePoolConfig memory _curvePool
    ) SCompStrategyBase(_nameStrategy, _governance, _strategist, _controller, _want, _tokenCompound, _pid, _feeConfig, _curvePool) {
    }

    function setVariancePrice(uint _variant) external {
        _onlyGovernance();
        require(_variant <= PRECISION, "variant must be less than PRECISION");
        variantPrice = _variant;
    }

    /// ===== View Functions =====
    function version() virtual override external pure returns (string memory) {
        return "1.0";
    }

    function _getAmountOutMinAddLiquidity(uint _amount) virtual override public view returns(uint){
        // check diff amount out and previous amounts out
        uint amountCurveOut;
        uint amountCurveOutPrevious;
        if ( curvePool.numElements == 2 ) {
            uint[2] memory amounts;
            amounts[curvePool.tokenCompoundPosition] = _amount;
            amountCurveOutPrevious = ICurveFi(curvePool.swap).calc_token_amount(amounts, true, true);
            amountCurveOut = ICurveFi(curvePool.swap).calc_token_amount(amounts, true);
        } else if ( curvePool.numElements == 3 ) {
            uint[3] memory amounts;
            amounts[curvePool.tokenCompoundPosition] = _amount;
            amountCurveOutPrevious = ICurveFi(curvePool.swap).calc_token_amount(amounts, true, true);
            amountCurveOut = ICurveFi(curvePool.swap).calc_token_amount(amounts, true);
        } else {
            uint[4] memory amounts;
            amounts[curvePool.tokenCompoundPosition] = _amount;
            amountCurveOutPrevious = ICurveFi(curvePool.swap).calc_token_amount(amounts, true, true);
            amountCurveOut = ICurveFi(curvePool.swap).calc_token_amount(amounts, true);
        }

        uint diff = amountCurveOutPrevious > amountCurveOut ?
        amountCurveOutPrevious - amountCurveOut :
        amountCurveOut - amountCurveOutPrevious;
        require(amountCurveOutPrevious.mul(variantPrice).div(PRECISION) > diff, "diff min lp out");

        // slippage
        amountCurveOut -= amountCurveOut.mul(slippageLiquidity).div(PRECISION);
        return amountCurveOut;
    }

}