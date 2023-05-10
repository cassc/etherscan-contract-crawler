// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;
import "contracts/libraries/math/Sigmoid.sol";

contract MockSigmoid is Sigmoid {
    function p(uint256 x) public pure returns (uint256) {
        return Sigmoid._p(x);
    }

    function pInverse(uint256 x) public pure returns (uint256) {
        return Sigmoid._pInverse(x);
    }

    function safeAbsSub(uint256 a, uint256 b) public pure returns (uint256) {
        return Sigmoid._safeAbsSub(a, b);
    }

    function min(uint256 a, uint256 b) public pure returns (uint256) {
        return Sigmoid._min(a, b);
    }

    function max(uint256 a, uint256 b) public pure returns (uint256) {
        return Sigmoid._max(a, b);
    }

    function sqrt(uint256 x) public pure returns (uint256) {
        return Sigmoid._sqrt(x);
    }

    function pConstA() public pure returns (uint256) {
        return Sigmoid._P_A;
    }

    function pConstB() public pure returns (uint256) {
        return Sigmoid._P_B;
    }

    function pConstC() public pure returns (uint256) {
        return Sigmoid._P_C;
    }

    function pConstD() public pure returns (uint256) {
        return Sigmoid._P_D;
    }

    function pConstS() public pure returns (uint256) {
        return Sigmoid._P_S;
    }

    function pInverseConstC1() public pure returns (uint256) {
        return Sigmoid._P_INV_C_1;
    }

    function pInverseConstC2() public pure returns (uint256) {
        return Sigmoid._P_INV_C_2;
    }

    function pInverseConstC3() public pure returns (uint256) {
        return Sigmoid._P_INV_C_3;
    }

    function pInverseConstD0() public pure returns (uint256) {
        return Sigmoid._P_INV_D_0;
    }

    function pInverseConstD1() public pure returns (uint256) {
        return Sigmoid._P_INV_D_1;
    }
}