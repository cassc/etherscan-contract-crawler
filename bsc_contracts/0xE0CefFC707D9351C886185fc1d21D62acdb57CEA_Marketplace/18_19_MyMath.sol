// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol" ;

library MyMath {

    function add(uint256 a, uint256 b, string memory error) internal pure returns (uint256) {
        (bool isOk, uint256 value) = SafeMath.tryAdd(a, b) ;
        require(isOk, error) ;
        return value;
    }

    function sub(uint256 a, uint256 b, string memory error) internal pure returns (uint256) {
        (bool isOk, uint256 value) = SafeMath.trySub(a, b) ;
        require(isOk, error) ;
        return value;
    }

    function mul(uint256 a, uint256 b, string memory error) internal pure returns (uint256) {
        (bool isOk, uint256 value) = SafeMath.tryMul(a, b) ;
        require(isOk, error) ;
        return value;
    }

    function div(uint256 a, uint256 b, string memory error) internal pure returns (uint256) {
        (bool isOk, uint256 value) = SafeMath.tryDiv(a, b) ;
        require(isOk, error) ;
        return value;
    }

    function mod(uint256 a, uint256 b, string memory error) internal pure returns (uint256) {
        (bool isOk, uint256 value) = SafeMath.tryMod(a, b) ;
        require(isOk, error) ;
        return value;
    }
}