// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/ShackledMath.sol";

contract XShackledMath {
    constructor() {}

    function xmin(int256 a,int256 b) external pure returns (int256) {
        return ShackledMath.min(a,b);
    }

    function xmax(int256 a,int256 b) external pure returns (int256) {
        return ShackledMath.max(a,b);
    }

    function xmod(int256 n,int256 m) external pure returns (int256) {
        return ShackledMath.mod(n,m);
    }

    function xrandomIdx(bytes32 seedModifier,uint256 n,uint256 m) external pure returns (uint256[] memory) {
        return ShackledMath.randomIdx(seedModifier,n,m);
    }

    function xget2dArray(uint256 m,uint256 q,int256 value) external pure returns (int256[][] memory) {
        return ShackledMath.get2dArray(m,q,value);
    }

    function xabs(int256 x) external pure returns (int256) {
        return ShackledMath.abs(x);
    }

    function xsqrt(int256 y) external pure returns (int256) {
        return ShackledMath.sqrt(y);
    }

    function xhypot(int256 x,int256 y) external pure returns (int256) {
        return ShackledMath.hypot(x,y);
    }

    function xvector3Add(int256[3] calldata v1,int256[3] calldata v2) external pure returns (int256[3] memory) {
        return ShackledMath.vector3Add(v1,v2);
    }

    function xvector3Sub(int256[3] calldata v1,int256[3] calldata v2) external pure returns (int256[3] memory) {
        return ShackledMath.vector3Sub(v1,v2);
    }

    function xvector3MulScalar(int256[3] calldata v,int256 a) external pure returns (int256[3] memory) {
        return ShackledMath.vector3MulScalar(v,a);
    }

    function xvector3DivScalar(int256[3] calldata v,int256 a) external pure returns (int256[3] memory) {
        return ShackledMath.vector3DivScalar(v,a);
    }

    function xvector3Len(int256[3] calldata v) external pure returns (int256) {
        return ShackledMath.vector3Len(v);
    }

    function xvector3NormX(int256[3] calldata v,int256 fidelity) external pure returns (int256[3] memory) {
        return ShackledMath.vector3NormX(v,fidelity);
    }

    function xvector3Dot(int256[3] calldata v1,int256[3] calldata v2) external view returns (int256) {
        return ShackledMath.vector3Dot(v1,v2);
    }

    function xcrossProduct(int256[3] calldata v1,int256[3] calldata v2) external pure returns (int256[3] memory) {
        return ShackledMath.crossProduct(v1,v2);
    }

    function xvector12Lerp(int256[12] calldata v1,int256[12] calldata v2,int256 ir,int256 scaleFactor) external view returns (int256[12] memory) {
        return ShackledMath.vector12Lerp(v1,v2,ir,scaleFactor);
    }

    function xvector12Sub(int256[12] calldata v1,int256[12] calldata v2) external view returns (int256[12] memory) {
        return ShackledMath.vector12Sub(v1,v2);
    }

    function xmapRangeToRange(int256 num,int256 inMin,int256 inMax,int256 outMin,int256 outMax) external pure returns (int256) {
        return ShackledMath.mapRangeToRange(num,inMin,inMax,outMin,outMax);
    }
}