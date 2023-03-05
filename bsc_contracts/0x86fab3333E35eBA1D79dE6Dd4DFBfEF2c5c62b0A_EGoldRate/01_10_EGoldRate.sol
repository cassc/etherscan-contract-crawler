//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

import "../library/EGoldUtils.sol";

contract EGoldRate is AccessControl {
    using SafeMath for uint256;

    IUniswapV2Pair private lp;

    address private baseToken;

    address private paymentToken;

    uint8 private rateType;

    constructor( uint8 _rateType , address _lp , address _DFA ) AccessControl() {
        _setupRole(DEFAULT_ADMIN_ROLE, _DFA);

        lp = IUniswapV2Pair(_lp);
        rateType = _rateType;
    }

    function setRateType( uint8 _rateType ) external onlyRole(DEFAULT_ADMIN_ROLE)  {
        rateType = _rateType;
    }

    function setLPTokenT1( address _lp ) external onlyRole(DEFAULT_ADMIN_ROLE)  {
        lp = IUniswapV2Pair(_lp);
    }

    function setBaseTokenT1( address _baseToken ) external onlyRole(DEFAULT_ADMIN_ROLE){
        baseToken = _baseToken;
    }

    function setPaymentTokenT1( address _paymentToken ) external onlyRole(DEFAULT_ADMIN_ROLE){
        paymentToken = _paymentToken;
    }

    function fetchRateType( ) external view returns ( uint8 ){
        return rateType;
    }

    function fetchLPT1( ) external view returns ( address ){
        return address(lp);
    }

    function fetchBaseTokenT1( ) external view returns ( address ){
        return baseToken;
    }

    function fetchPaymentTokenT1( ) external view returns ( address ){
        return baseToken;
    }

    function fetchRate( uint256 _amt ) external view returns ( uint256 ){
        uint256 tokenPrice;
        if( rateType == 0 ){
            return _amt * 1 ether;
        } else if (rateType == 1) {
            address token0 = lp.token0();
            address token1 = lp.token1();
            (uint112 reserve0, uint112 reserve1, ) = lp.getReserves();

            uint256 token0Price = 0;
            uint256 token1Price = 0;

            if (token0 == baseToken) {
                token0Price = 1 ether;
                token1Price = (uint256(reserve0) * token0Price) / uint256(reserve1);
                tokenPrice = token1Price;
            } else if (token1 == baseToken) {
                token1Price = 1 ether;
                token0Price = (uint256(reserve1) * token1Price) / uint256(reserve0);
                tokenPrice = token0Price;
            } else {
                revert("Token not found in pool");
            }
            return tokenPrice * _amt;

        }else{
            return tokenPrice;
        }
    }
}