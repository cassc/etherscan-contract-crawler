// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ShackledUtils.sol";
import "./ShackledMath.sol";

library ShackledCoords {
    /** @dev scale and translate the verts
    this can be effectively disabled with a scale of 1 and translate of [0, 0, 0]
     */
    function convertToWorldSpaceWithModelTransform(
        int256[3][3][] memory tris,
        int256 scale,
        int256[3] memory position
    ) external view returns (int256[3][] memory) {
        int256[3][] memory verts = ShackledUtils.flattenTris(tris);

        // Scale model matrices are easy, just multiply through by the scale value
        int256[3][] memory scaledVerts = new int256[3][](verts.length);

        for (uint256 i = 0; i < verts.length; i++) {
            scaledVerts[i][0] = verts[i][0] * scale + position[0];
            scaledVerts[i][1] = verts[i][1] * scale + position[1];
            scaledVerts[i][2] = verts[i][2] * scale + position[2];
        }
        return scaledVerts;
    }

    /** @dev run backfaceCulling to save future operations on faces that aren't seen by the camera*/
    function backfaceCulling(
        int256[3][3][] memory trisWorldSpace,
        int256[3][3][] memory trisCols
    )
        external
        view
        returns (
            int256[3][3][] memory culledTrisWorldSpace,
            int256[3][3][] memory culledTrisCols
        )
    {
        culledTrisWorldSpace = new int256[3][3][](trisWorldSpace.length);
        culledTrisCols = new int256[3][3][](trisCols.length);

        uint256 nextIx;

        for (uint256 i = 0; i < trisWorldSpace.length; i++) {
            int256[3] memory v1 = trisWorldSpace[i][0];
            int256[3] memory v2 = trisWorldSpace[i][1];
            int256[3] memory v3 = trisWorldSpace[i][2];
            int256[3] memory norm = ShackledMath.crossProduct(
                ShackledMath.vector3Sub(v1, v2),
                ShackledMath.vector3Sub(v2, v3)
            );
            /// since shackled has a static positioned camera at the origin,
            /// the points are already in view space, relaxing the backfaceCullingCond
            int256 backfaceCullingCond = ShackledMath.vector3Dot(v1, norm);
            if (backfaceCullingCond < 0) {
                culledTrisWorldSpace[nextIx] = trisWorldSpace[i];
                culledTrisCols[nextIx] = trisCols[i];
                nextIx++;
            }
        }
        /// remove any empty slots
        uint256 nToCull = culledTrisWorldSpace.length - nextIx;
        /// cull uneeded tris
        assembly {
            mstore(
                culledTrisWorldSpace,
                sub(mload(culledTrisWorldSpace), nToCull)
            )
        }
        /// cull uneeded cols
        assembly {
            mstore(culledTrisCols, sub(mload(culledTrisCols), nToCull))
        }
    }

    /**@dev calculate verts in camera space */
    function convertToCameraSpaceViaVertexShader(
        int256[3][] memory vertsWorldSpace,
        int256 canvasDim,
        bool perspCamera
    ) external view returns (int256[3][] memory) {
        // get the camera matrix as a numerator and denominator
        int256[4][4][2] memory cameraMatrix;
        if (perspCamera) {
            cameraMatrix = getCameraMatrixPersp();
        } else {
            cameraMatrix = getCameraMatrixOrth(canvasDim);
        }

        int256[4][4] memory nM = cameraMatrix[0]; // camera matrix numerator
        int256[4][4] memory dM = cameraMatrix[1]; // camera matrix denominator

        int256[3][] memory verticesCameraSpace = new int256[3][](
            vertsWorldSpace.length
        );

        for (uint256 i = 0; i < vertsWorldSpace.length; i++) {
            // Convert from 3D to 4D homogenous coordinate system
            int256[3] memory vert = vertsWorldSpace[i];

            // Make a copy of vert ("homoVertex")
            int256[] memory hv = new int256[](vert.length + 1);

            for (uint256 j = 0; j < vert.length; j++) {
                hv[j] = vert[j];
            }

            // Insert 1 at final position in copy of vert
            hv[hv.length - 1] = 1;

            int256 x = ((hv[0] * nM[0][0]) / dM[0][0]) +
                ((hv[1] * nM[0][1]) / dM[0][1]) +
                ((hv[2] * nM[0][2]) / dM[0][2]) +
                (nM[0][3] / dM[0][3]);

            int256 y = ((hv[0] * nM[1][0]) / dM[1][0]) +
                ((hv[1] * nM[1][1]) / dM[1][1]) +
                ((hv[2] * nM[1][2]) / dM[1][2]) +
                (nM[1][3] / dM[1][0]);

            int256 z = ((hv[0] * nM[2][0]) / dM[2][0]) +
                ((hv[1] * nM[2][1]) / dM[2][1]) +
                ((hv[2] * nM[2][2]) / dM[2][2]) +
                (nM[2][3] / dM[2][3]);

            int256 w = ((hv[0] * nM[3][0]) / dM[3][0]) +
                ((hv[1] * nM[3][1]) / dM[3][1]) +
                ((hv[2] * nM[3][2]) / dM[3][2]) +
                (nM[3][3] / dM[3][3]);

            if (w != 1) {
                x = (x * 1e3) / w;
                y = (y * 1e3) / w;
                z = (z * 1e3) / w;
            }

            // Turn it back into a 3-vector
            // Add it to the ordered list
            verticesCameraSpace[i] = [x, y, z];
        }

        return verticesCameraSpace;
    }

    /** @dev generate an orthographic camera matrix */
    function getCameraMatrixOrth(int256 canvasDim)
        internal
        pure
        returns (int256[4][4][2] memory)
    {
        int256 canvasHalf = canvasDim / 2;

        // Left, right, top, bottom
        int256 r = ShackledMath.abs(canvasHalf);
        int256 l = -canvasHalf;
        int256 t = ShackledMath.abs(canvasHalf);
        int256 b = -canvasHalf;

        // Z settings (near and far)
        /// multiplied by 1e3
        int256 n = 1;
        int256 f = 1024;

        // Get the orthographic transform matrix
        // as a numerator and denominator

        int256[4][4] memory cameraMatrixNum = [
            [int256(2), 0, 0, -(r + l)],
            [int256(0), 2, 0, -(t + b)],
            [int256(0), 0, -2, -(f + n)],
            [int256(0), 0, 0, 1]
        ];

        int256[4][4] memory cameraMatrixDen = [
            [int256(r - l), 1, 1, (r - l)],
            [int256(1), (t - b), 1, (t - b)],
            [int256(1), 1, (f - n), (f - n)],
            [int256(1), 1, 1, 1]
        ];

        int256[4][4][2] memory cameraMatrix = [
            cameraMatrixNum,
            cameraMatrixDen
        ];

        return cameraMatrix;
    }

    /** @dev generate a perspective camera matrix */
    function getCameraMatrixPersp()
        internal
        pure
        returns (int256[4][4][2] memory)
    {
        // Z settings (near and far)
        /// multiplied by 1e3
        int256 n = 500;
        int256 f = 501;

        // Get the perspective transform matrix
        // as a numerator and denominator

        // parameter = 1 / tan(fov in degrees / 2)
        // 0.1763 = 1 / tan(160 / 2)
        // 1.428 = 1 / tan(70 / 2)
        // 1.732 = 1 / tan(60 / 2)
        // 2.145 = 1 / tan(50 / 2)

        int256[4][4] memory cameraMatrixNum = [
            [int256(2145), 0, 0, 0],
            [int256(0), 2145, 0, 0],
            [int256(0), 0, f, -f * n],
            [int256(0), 0, 1, 0]
        ];

        int256[4][4] memory cameraMatrixDen = [
            [int256(1000), 1, 1, 1],
            [int256(1), 1000, 1, 1],
            [int256(1), 1, f - n, f - n],
            [int256(1), 1, 1, 1]
        ];

        int256[4][4][2] memory cameraMatrix = [
            cameraMatrixNum,
            cameraMatrixDen
        ];

        return cameraMatrix;
    }
}