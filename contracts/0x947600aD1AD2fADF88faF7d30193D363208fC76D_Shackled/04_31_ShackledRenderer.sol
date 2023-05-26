// // SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ShackledCoords.sol";
import "./ShackledRasteriser.sol";
import "./ShackledUtils.sol";
import "./ShackledStructs.sol";

library ShackledRenderer {
    uint256 constant outputHeight = 512;
    uint256 constant outputWidth = 512;

    /** @dev take any geometry, render it, and return a bitmap image inside an SVG 
    this can be called to render the Shackled art collection (the output of ShackledGenesis.sol)
    or any other custom made geometry

    */
    function render(
        ShackledStructs.RenderParams memory renderParams,
        int256 canvasDim,
        bool returnSVG
    ) public view returns (string memory) {
        /// prepare the fragments
        int256[12][3][] memory trisFragments = prepareGeometryForRender(
            renderParams,
            canvasDim
        );

        /// run Bresenham's line algorithm to rasterize the fragments
        int256[12][] memory fragments = ShackledRasteriser.rasterise(
            trisFragments,
            canvasDim,
            renderParams.wireframe
        );

        fragments = ShackledRasteriser.depthTesting(fragments, canvasDim);

        if (renderParams.lightingParams.applyLighting) {
            /// apply lighting (Blinn phong)
            fragments = ShackledRasteriser.lightScene(
                fragments,
                renderParams.lightingParams
            );
        }

        /// get the background
        int256[5][] memory background = ShackledRasteriser.getBackground(
            canvasDim,
            renderParams.backgroundColor
        );

        /// place each fragment in an encoded bitmap
        string memory encodedBitmap = ShackledUtils.getEncodedBitmap(
            fragments,
            background,
            canvasDim,
            renderParams.invert
        );

        if (returnSVG) {
            /// insert the bitmap into an encoded svg (to be accepted by OpenSea)
            return
                ShackledUtils.getSVGContainer(
                    encodedBitmap,
                    canvasDim,
                    outputHeight,
                    outputWidth
                );
        } else {
            return encodedBitmap;
        }
    }

    /** @dev prepare the triangles and colors for rasterization
     */
    function prepareGeometryForRender(
        ShackledStructs.RenderParams memory renderParams,
        int256 canvasDim
    ) internal view returns (int256[12][3][] memory) {
        /// convert geometry and colors from PLY standard into Shackled format
        /// create the final triangles and colors that will be rendered
        /// by pulling the numbers out of the faces array
        /// and using them to index into the verts and colors arrays
        /// make copies of each coordinate and color
        int256[3][3][] memory tris = new int256[3][3][](
            renderParams.faces.length
        );
        int256[3][3][] memory trisCols = new int256[3][3][](
            renderParams.faces.length
        );

        for (uint256 i = 0; i < renderParams.faces.length; i++) {
            for (uint256 j = 0; j < 3; j++) {
                for (uint256 k = 0; k < 3; k++) {
                    /// copy the values from verts and cols arrays
                    /// using the faces lookup array to index into them
                    tris[i][j][k] = renderParams.verts[
                        renderParams.faces[i][j]
                    ][k];
                    trisCols[i][j][k] = renderParams.cols[
                        renderParams.faces[i][j]
                    ][k];
                }
            }
        }

        /// convert the fragments from model to world space
        int256[3][] memory vertsWorldSpace = ShackledCoords
            .convertToWorldSpaceWithModelTransform(
                tris,
                renderParams.objScale,
                renderParams.objPosition
            );

        /// convert the vertices back to triangles in world space
        int256[3][3][] memory trisWorldSpace = ShackledUtils
            .unflattenVertsToTris(vertsWorldSpace);

        /// implement backface culling
        if (renderParams.backfaceCulling) {
            (trisWorldSpace, trisCols) = ShackledCoords.backfaceCulling(
                trisWorldSpace,
                trisCols
            );
        }

        /// update vertsWorldSpace
        vertsWorldSpace = ShackledUtils.flattenTris(trisWorldSpace);

        /// convert the fragments from world to camera space
        int256[3][] memory vertsCameraSpace = ShackledCoords
            .convertToCameraSpaceViaVertexShader(
                vertsWorldSpace,
                canvasDim,
                renderParams.perspCamera
            );

        /// convert the vertices back to triangles in camera space
        int256[3][3][] memory trisCameraSpace = ShackledUtils
            .unflattenVertsToTris(vertsCameraSpace);

        int256[12][3][] memory trisFragments = ShackledRasteriser
            .initialiseFragments(
                trisCameraSpace,
                trisWorldSpace,
                trisCols,
                canvasDim
            );

        return trisFragments;
    }
}