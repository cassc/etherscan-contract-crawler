// c077ffa5099a4bfaa04669bbc798b1408ec6fa3e
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.17;

import "EnumerableSet.sol";
import "ACLBase.sol";

interface IOracle {
    function getUSDValue(address _token, uint256 _amount) external view returns(uint256);
}


abstract contract DEXBase is ACLBase {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) swapInTokenWhitelist;
    mapping(bytes32 => EnumerableSet.AddressSet) swapOutTokenWhitelist;

    uint256 private constant SLIPPAGE_BASE = 10000;
    IOracle internal oracle;
    mapping(bytes32 => uint256) internal role_maxSlippagePercent;
    
    struct SwapInToken {
        bytes32 role;
        address token; 
        bool tokenStatus;
    }

    struct SwapOutToken {
        bytes32 role;
        address token; 
        bool tokenStatus;
    }

    function setSwapInToken(bytes32 _role, address _token, bool _tokenStatus) external onlySafe{   // sell
        if(_tokenStatus){
            swapInTokenWhitelist[_role].add(_token);
        }else{
            swapInTokenWhitelist[_role].remove(_token);
        }
    }

    function setSwapInTokens(SwapInToken[] calldata _swapInToken) external onlySafe{    
        for (uint i=0; i < _swapInToken.length; i++) { 
            if (_swapInToken[i].tokenStatus){
                swapInTokenWhitelist[_swapInToken[i].role].add(_swapInToken[i].token);
            }else{
                swapInTokenWhitelist[_swapInToken[i].role].remove(_swapInToken[i].token);
            }
        }
    }

    function getSwapInTokens(bytes32 _role, address token) external view returns (bool){
        return swapInTokenWhitelist[_role].contains(token);
    }

    function getSwapInTokens(bytes32 _role) external view returns (address[] memory tokens){
        return swapInTokenWhitelist[_role].values();
    }


    function setSwapOutToken(bytes32 _role, address _token, bool _tokenStatus) external onlySafe{   // buy
        if(_tokenStatus){
            swapOutTokenWhitelist[_role].add(_token);
        }else{
            swapOutTokenWhitelist[_role].remove(_token);
        }
    }


    function setSwapOutTokens(SwapOutToken[] calldata _swapOutToken) external onlySafe{    
        for (uint i=0; i < _swapOutToken.length; i++) { 
            if(_swapOutToken[i].tokenStatus){
                swapOutTokenWhitelist[_swapOutToken[i].role].add(_swapOutToken[i].token);
            }else{
                swapOutTokenWhitelist[_swapOutToken[i].role].remove(_swapOutToken[i].token);
            }
        }
    }

    function getSwapOutToken(bytes32 _role, address token) external view returns (bool){
        return swapOutTokenWhitelist[_role].contains(token);
    }

    function getSwapOutTokens(bytes32 _role) external view returns (address[] memory tokens){
        return swapOutTokenWhitelist[_role].values();
    }

    function setOracle(address _oracle) internal onlySafe{
        oracle = IOracle(_oracle);
    }

    function setRoleSlippage(bytes32 _role, uint256 _precentage) internal onlySafe {
        role_maxSlippagePercent[_role] = _precentage;
    }

    function slippageCheck(address token0, address token1, uint256 amountIn, uint256 amountOut) internal view {
        uint256 valueInput = oracle.getUSDValue(token0, amountIn);
        uint256 valueOutput = oracle.getUSDValue(token1, amountOut);
        require(valueOutput >= valueInput * (SLIPPAGE_BASE - role_maxSlippagePercent[_checkedRole]) / SLIPPAGE_BASE, "Slippage is too high");

    }

    function swapInOutTokenCheck(address _inToken, address _outToken) internal view {  
        require(swapInTokenWhitelist[_checkedRole].contains(_inToken),"token not allowed");
        require(swapOutTokenWhitelist[_checkedRole].contains(_outToken),"token not allowed");
    }

    function swapInTokenCheck(address _inToken) internal view {  
        require(swapInTokenWhitelist[_checkedRole].contains(_inToken),"token not allowed");
    }

    function swapOutTokenCheck(address _outToken) internal view {  
        require(swapOutTokenWhitelist[_checkedRole].contains(_outToken),"token not allowed");
    }


    uint256[50] private __gap;

}