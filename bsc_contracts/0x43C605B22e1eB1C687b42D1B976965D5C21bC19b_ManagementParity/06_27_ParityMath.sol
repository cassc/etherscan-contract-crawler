// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./ParityData.sol"; 
library ParityMath {
    function add(ParityData.Amount storage _var1, ParityData.Amount memory _var2) internal {
        _var1.alpha = _var1.alpha + _var2.alpha;
        _var1.beta = _var1.beta + _var2.beta;
        _var1.gamma = _var1.gamma + _var2.gamma;
    }

    function sub(ParityData.Amount storage _var1, ParityData.Amount memory _var2) internal {
        require((_var1.alpha >= _var2.alpha ) &&
        (_var1.beta >= _var2.beta ) &&
        (_var1.gamma >= _var2.gamma ), "Formation.Fi: negative number");
        _var1.alpha = _var1.alpha - _var2.alpha;
        _var1.beta = _var1.beta - _var2.beta;
        _var1.gamma = _var1.gamma - _var2.gamma;
    }


    function add2(ParityData.Amount memory _var1, ParityData.Amount memory _var2) internal pure
        returns (ParityData.Amount memory _var) {
        _var.alpha = _var1.alpha + _var2.alpha;
        _var.beta = _var1.beta + _var2.beta;
        _var.gamma = _var1.gamma + _var2.gamma;
    }

    function sub2(ParityData.Amount memory _var1, ParityData.Amount memory _var2) internal pure
        returns (ParityData.Amount memory _var) {
        require((_var1.alpha >= _var2.alpha ) &&
        (_var1.beta >= _var2.beta ) &&
        (_var1.gamma >= _var2.gamma ), "Formation.Fi: negative number");
        _var.alpha = _var1.alpha - _var2.alpha;
        _var.beta = _var1.beta - _var2.beta;
        _var.gamma = _var1.gamma - _var2.gamma;
    }


    function mul(ParityData.Amount storage _var1, uint256 _coef) internal {
        _var1.alpha = _var1.alpha * _coef ;
        _var1.beta =  _var1.beta * _coef ;
        _var1.gamma = _var1.gamma * _coef ;
    }

    function div2(ParityData.Amount memory _var1, uint256 _coef) internal pure
        returns (ParityData.Amount memory _var) {
        _var.alpha =  _var1.alpha /_coef ;
        _var.beta =  _var1.beta /_coef;
        _var.gamma =  _var1.gamma /_coef;
    }

    function mulMultiCoef(ParityData.Amount storage _var1, uint256[3] memory _coef) internal {
        _var1.alpha = _coef[0] * _var1.alpha;
        _var1.beta = _coef[1] * _var1.beta;
        _var1.gamma = _coef[2] * _var1.gamma;
    }

    function mulMultiCoef2(ParityData.Amount memory _var1, uint256[3] memory _coef) internal pure
        returns (ParityData.Amount memory _var) {
        _var.alpha = _coef[0] * _var1.alpha;
        _var.beta = _coef[1] * _var1.beta;
        _var.gamma = _coef[2] * _var1.gamma;
    }

    function mulDiv(ParityData.Amount storage _var1, uint256 _mulcoef, uint256 _divcoef) internal {
        _var1.alpha = Math.mulDiv(_var1.alpha, _mulcoef, _divcoef);
        _var1.beta = Math.mulDiv(_var1.beta, _mulcoef, _divcoef);
        _var1.gamma = Math.mulDiv(_var1.gamma, _mulcoef, _divcoef);
    }

    function mulDiv2(ParityData.Amount memory _var1, uint256 _mulcoef, uint256 _divcoef) internal pure 
        returns (ParityData.Amount memory _var) {
        _var.alpha = Math.mulDiv(_var1.alpha, _mulcoef, _divcoef);
        _var.beta = Math.mulDiv(_var1.beta, _mulcoef, _divcoef);
        _var.gamma = Math.mulDiv(_var1.gamma, _mulcoef, _divcoef);
    }

    function mulMultiCoefDiv(ParityData.Amount storage _var1, uint256[3] memory _mulcoef, uint256 _divcoef) internal{
        _var1.alpha = Math.mulDiv(_var1.alpha, _mulcoef[0], _divcoef);
        _var1.beta = Math.mulDiv(_var1.beta, _mulcoef[1], _divcoef);
        _var1.gamma = Math.mulDiv(_var1.gamma, _mulcoef[2], _divcoef);
    }

    function mulDivMultiCoef(ParityData.Amount storage _var1, uint256 _mulcoef, uint256[3] memory _mulDiv) internal{
        _var1.alpha = Math.mulDiv(_var1.alpha, _mulcoef, _mulDiv[0]);
        _var1.beta = Math.mulDiv(_var1.beta, _mulcoef, _mulDiv[1]);
        _var1.gamma = Math.mulDiv(_var1.gamma, _mulcoef, _mulDiv[2]);
    }

    function mulMultiCoefDiv2(ParityData.Amount memory _var1, uint256[3] memory _mulcoef, uint256 _divcoef) internal pure
        returns (ParityData.Amount memory _var){
        _var.alpha = Math.mulDiv(_var1.alpha, _mulcoef[0], _divcoef);
        _var.beta =  Math.mulDiv(_var1.beta, _mulcoef[1], _divcoef);
        _var.gamma = Math.mulDiv(_var1.gamma, _mulcoef[2], _divcoef);

    }
    function mulDivMultiCoef2(ParityData.Amount memory _var1, uint256 _mulcoef, uint256[3] memory _mulDiv) internal pure 
        returns (ParityData.Amount memory _var) {
        _var.alpha = Math.mulDiv(_var1.alpha, _mulcoef, _mulDiv[0]);
        _var.beta = Math.mulDiv(_var1.beta, _mulcoef, _mulDiv[1]);
        _var.gamma = Math.mulDiv(_var1.gamma, _mulcoef, _mulDiv[2]);
    }


}