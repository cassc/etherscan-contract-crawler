// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/** 
 * @title Functions for share valuation
 */
contract MathUtil {

    uint256 internal constant ONE_DEC18 = 10**18;
    uint256 internal constant THRESH_DEC18 =  10000000000000000;//0.01
    /**
     * @notice Cubic root with Halley approximation
     *         Number 1e18 decimal
     * @param _v     number for which we calculate x**(1/3)
     * @return returns _v**(1/3)
     */
    function _cubicRoot(uint256 _v) internal pure returns (uint256) {
        uint256 x = ONE_DEC18;
        uint256 xOld;
        bool cond;
        do {
            xOld = x;
            uint256 powX3 = _mulD18(_mulD18(x, x), x);
            x = _mulD18(x, _divD18( (powX3 + 2 * _v) , (2 * powX3 + _v)));
            cond = xOld > x ? xOld - x > THRESH_DEC18 : x - xOld > THRESH_DEC18;
        } while ( cond );
        return x;
    }

    function _mulD18(uint256 _a, uint256 _b) internal pure returns(uint256) {
        return _a * _b / ONE_DEC18;
    }

    function _divD18(uint256 _a, uint256 _b) internal pure returns(uint256) {
        return (_a * ONE_DEC18) / _b ;
    }

    function _power3(uint256 _x) internal pure returns(uint256) {
        return _mulD18(_mulD18(_x, _x), _x);
    }

}