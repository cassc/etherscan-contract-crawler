// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/ShackledRasteriser.sol";

contract XShackledRasteriser {
    constructor() {}

    function xinitialiseFragments(int256[3][3][] calldata trisCameraSpace,int256[3][3][] calldata trisWorldSpace,int256[3][3][] calldata trisCols,int256 canvasDim) external view returns (int256[12][3][] memory) {
        return ShackledRasteriser.initialiseFragments(trisCameraSpace,trisWorldSpace,trisCols,canvasDim);
    }

    function xrasterise(int256[12][3][] calldata trisFragments,int256 canvasDim,bool wireframe) external view returns (int256[12][] memory) {
        return ShackledRasteriser.rasterise(trisFragments,canvasDim,wireframe);
    }

    function xrunBresenhamsAlgorithm(int256[12] calldata f1,int256[12] calldata f2,int256 canvasDim,int256[12][] calldata bresTriFragments,uint256 nextBresTriFragmentIx) external view returns (int256[12][] memory, uint256) {
        return ShackledRasteriser.runBresenhamsAlgorithm(f1,f2,canvasDim,bresTriFragments,nextBresTriFragmentIx);
    }

    function xbresenhamsInner(ShackledRasteriser.BresenhamsVars calldata vars,int256 mag,int256[12] calldata fa,int256[12] calldata fb,int256 canvasDim,int256[12][] calldata bresTriFragments,uint256 nextBresTriFragmentIx) external view returns (int256[12][] memory, uint256) {
        return ShackledRasteriser.bresenhamsInner(vars,mag,fa,fb,canvasDim,bresTriFragments,nextBresTriFragmentIx);
    }

    function xrunScanline(int256[12][] calldata bresTriFragments,int256[12][] calldata fragments,uint256 nextFragmentsIx,int256 canvasDim) external view returns (int256[12][] memory, uint256) {
        return ShackledRasteriser.runScanline(bresTriFragments,fragments,nextFragmentsIx,canvasDim);
    }

    function xgetRowFragIndices(int256[12][] calldata bresTriFragments,int256 canvasDim) external view returns (int256[][] memory, uint256[] memory) {
        return ShackledRasteriser.getRowFragIndices(bresTriFragments,canvasDim);
    }

    function xdepthTesting(int256[12][] calldata fragments,int256 canvasDim) external view returns (int256[12][] memory) {
        return ShackledRasteriser.depthTesting(fragments,canvasDim);
    }

    function xlightScene(int256[12][] calldata fragments,ShackledStructs.LightingParams calldata lp) external view returns (int256[12][] memory) {
        return ShackledRasteriser.lightScene(fragments,lp);
    }

    function xcalculateSpecular(int256 lightSpecPower,int256 hnDot,int256 fidelity,uint256 inverseShininess) external pure returns (int256) {
        return ShackledRasteriser.calculateSpecular(lightSpecPower,hnDot,fidelity,inverseShininess);
    }

    function xgetBackground(int256 canvasDim,int256[3][2] calldata backgroundColor) external view returns (int256[5][] memory) {
        return ShackledRasteriser.getBackground(canvasDim,backgroundColor);
    }
}