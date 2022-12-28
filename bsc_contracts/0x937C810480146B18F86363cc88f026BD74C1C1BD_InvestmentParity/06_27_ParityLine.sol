// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; 

contract ParityLine is Ownable  {
    using Math for uint256;

    uint256 public a = 7876 * 1e14;
    uint256 public b = 8 * 1e16;
    uint256 public weight_A = 8 * 1e17;
    uint256 public weight_B = 2 * 1e17;
    uint256 public sigma_a = 6275 * 1e14;
    uint256 public sigma_b = 6127 * 1e14;
    uint256 public sigma_c = 473 * 1e14;
    uint256 public r_a = 5 * 1e17;
    uint256 public r_b = 2 * 1e17;
    uint256 public r_c = 8 * 1e16;

    event SetSigma(uint256 _sigma_a, uint256 _sigma_b, uint256 _sigma_c);
    event SetParityLineCoeff(uint256 _a,uint256 _b);
    event SetReturns(uint256 _r_a, uint256 _r_b, uint256 _r_c);
    event SetWeightCoeff(uint256 _weight_A, uint256  _weight_B);

    function getMinReturn() public view returns (uint256 _return){
        _return = r_c;
    }

    function getMaxReturn() public view returns (uint256 _return){
        _return = Math.max(r_a, r_b);
    }

    function getMinRisk() public view returns (uint256 _risk){
        (_risk, , , ) = ConvertReturn(getMinReturn());
    }

    function getMaxRisk() public view returns (uint256 _risk){
        (_risk, , , ) = ConvertReturn(getMaxReturn());
    }

    function setSigma(uint256 _sigma_a, uint256 _sigma_b, uint256 _sigma_c) 
        external onlyOwner {
        sigma_a = _sigma_a;
        sigma_b = _sigma_b;
        sigma_c = _sigma_c; 
        emit SetSigma(_sigma_a, _sigma_b,  _sigma_c);
    }

    function setParityLineCoeff(uint256 _a, uint256 _b) 
        external onlyOwner {
        a = _a;
        b = _b;
        emit SetParityLineCoeff(_a, _b);
    }

    function setReturns(uint256 _r_a, uint256 _r_b, uint256 _r_c) 
        external onlyOwner {
        r_a = _r_a;
        r_b = _r_b;
        r_c = _r_c;
        emit SetReturns(_r_a, _r_b, _r_c);
    }


    function setWeightCoeff(uint256 _weight_A, uint256 _weight_B) 
        external onlyOwner {
        weight_A = _weight_A;
        weight_B = _weight_B;
        emit SetWeightCoeff (_weight_A, _weight_B);
    }

    function ConvertRisk(uint256 _risk) public view 
        returns (uint256 _return, uint256 _weight_alpha, 
        uint256 _weight_beta, uint256 _weight_gamma) {
        require((_risk >= getMinRisk()) && (_risk <= getMaxRisk()), 
        "Formation.Fi: Rik is out of range" );
        _return = ((a * _risk) / 10**18) + b;
        (_weight_alpha,  _weight_beta,  _weight_gamma) = _calculateWeights(_return);
    }


    function ConvertReturn(uint256 _return) public view 
        returns (uint256 _risk, uint256 _weight_alpha, 
        uint256 _weight_beta, uint256 _weight_gamma) {
        require((_return >= getMinReturn()) && (_return <= getMaxReturn()), 
        "Formation.Fi: Return is out of range" );
        _risk = ((_return - b) * 10**18)/ a;
        (_weight_alpha,  _weight_beta,  _weight_gamma) = _calculateWeights(_return);
    }

    function ConvertWeights(uint256 _weight_alpha, 
        uint256 _weight_beta, uint256 _weight_gamma) public view 
        returns (uint256 _risk, uint256 _return) {
        _return = (_weight_alpha * r_a + _weight_beta * r_b +
        _weight_gamma * r_c); 
        _risk = (_return -b * 10**18) / a;
        _return = _return/10**18;
    }

    function _calculateWeights( uint256 _return)  internal view
        returns (uint256 _weight_alpha, uint256 _weight_beta, uint256 _weight_gamma){
        uint256 _combinedReturn = combinedReturn();
        uint256 _w_Beta_Ind = w_Beta_Ind(_return ,  _combinedReturn);
        uint256 _g_weight = g_weight(_return,  _combinedReturn,  _w_Beta_Ind);
        uint256 _c_weight = c_weight(_return,  _combinedReturn, _w_Beta_Ind);
        uint256 _g_trim = g_trim( _g_weight);
        uint256 _c_trim = c_trim(_c_weight);
        _weight_beta = _c_trim * weight_B * _w_Beta_Ind / 10**18;
        _weight_gamma = _g_trim;
        _weight_alpha = 10**18 - _weight_beta - _weight_gamma;
    }


    function combinedReturn() internal view returns (uint256 _combinedReturn) {
    _combinedReturn =  (weight_A * r_a + weight_B * r_b)/10**18;
    }

    function w_Beta_Ind(uint256 _return , uint256 _combinedReturn) internal pure returns ( uint256 _result) {
        if ( _return <= _combinedReturn){
            _result = 1;
        }
        else {
            _result = 0;
        }
    }

    function g_weight(uint256 _return, uint256 _combinedReturn, uint256 _w_Beta_Ind)  
        internal view returns ( uint256 _result) {
        if (_w_Beta_Ind ==1){
            if (_combinedReturn >= _return){
                _result = (_combinedReturn - _return) * 10**18 / (_combinedReturn - r_c);
            }
        }

        else {
            if ( r_a >= _return){
                _result = (r_a - _return) * 10**18 / (r_a - r_c);
            }
        }
    }

    function c_weight(uint256 _return, uint256 _combinedReturn, uint256 _w_Beta_Ind)  
        internal view returns (uint256 _result) {
        if ((_w_Beta_Ind  != 0) && ( _return >= r_c)){
            _result =  (_return - r_c) * 10**18 /(_combinedReturn - r_c);
        }
    }

    function g_trim( uint256 _g_weight) internal pure returns ( uint256 _result) {
        _result = Math.min( Math.max(_g_weight, 0), 10**18);
    }

    function c_trim( uint256 _c_weight) internal pure returns ( uint256 _result) {
        _result = Math.min( Math.max(_c_weight, 0), 10**18);
    }

}