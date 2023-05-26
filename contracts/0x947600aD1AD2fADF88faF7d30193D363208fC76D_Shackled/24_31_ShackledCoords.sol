// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/ShackledCoords.sol";

contract XShackledCoords {
    constructor() {}

    function xconvertToWorldSpaceWithModelTransform(int256[3][3][] calldata tris,int256 scale,int256[3] calldata position) external view returns (int256[3][] memory) {
        return ShackledCoords.convertToWorldSpaceWithModelTransform(tris,scale,position);
    }

    function xbackfaceCulling(int256[3][3][] calldata trisWorldSpace,int256[3][3][] calldata trisCols) external view returns (int256[3][3][] memory, int256[3][3][] memory) {
        return ShackledCoords.backfaceCulling(trisWorldSpace,trisCols);
    }

    function xconvertToCameraSpaceViaVertexShader(int256[3][] calldata vertsWorldSpace,int256 canvasDim,bool perspCamera) external view returns (int256[3][] memory) {
        return ShackledCoords.convertToCameraSpaceViaVertexShader(vertsWorldSpace,canvasDim,perspCamera);
    }

    function xgetCameraMatrixOrth(int256 canvasDim) external pure returns (int256[4][4][2] memory) {
        return ShackledCoords.getCameraMatrixOrth(canvasDim);
    }

    function xgetCameraMatrixPersp() external pure returns (int256[4][4][2] memory) {
        return ShackledCoords.getCameraMatrixPersp();
    }
}