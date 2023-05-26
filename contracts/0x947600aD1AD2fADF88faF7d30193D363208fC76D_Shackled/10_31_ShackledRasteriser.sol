// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ShackledUtils.sol";
import "./ShackledMath.sol";
import "./ShackledStructs.sol";

library ShackledRasteriser {
    /// define some constant lighting parameters
    int256 constant fidelity = int256(100); /// an extra paramater to improve numeric resolution
    int256 constant lightAmbiPower = int256(1); // Base light colour // was 0.5
    int256 constant lightDiffPower = int256(3e9); // Diffused light on surface relative strength
    int256 constant lightSpecPower = int256(1e7); // Specular reflection on surface relative strength
    uint256 constant inverseShininess = 10; // 'sharpness' of specular light on surface

    /// define a scale factor to use in lerp to avoid rounding errors
    int256 constant lerpScaleFactor = 1e3;

    /// storing variables used in the fragment lighting
    struct LightingVars {
        int256[3] fragCol;
        int256[3] fragNorm;
        int256[3] fragPos;
        int256[3] V;
        int256 vMag;
        int256[3] N;
        int256 nMag;
        int256[3] L;
        int256 lMag;
        int256 falloff;
        int256 lnDot;
        int256 lambertian;
    }

    /// store variables used in Bresenham's line algorithm
    struct BresenhamsVars {
        int256 x;
        int256 y;
        int256 dx;
        int256 dy;
        int256 sx;
        int256 sy;
        int256 err;
        int256 e2;
    }

    /// store variables used when running the scanline algorithm
    struct ScanlineVars {
        int256 left;
        int256 right;
        int256[12] leftFrag;
        int256[12] rightFrag;
        int256 dx;
        int256 ir;
        int256 newFragRow;
        int256 newFragCol;
    }

    /** @dev initialise the fragments
        fragments are defined as:
        [
            canvas_x, canvas_y, depth,
            col_x, col_y, col_z,
            normal_x, normal_y, normal_z,
            world_x, world_y, world_z
        ]
        
     */
    function initialiseFragments(
        int256[3][3][] memory trisCameraSpace,
        int256[3][3][] memory trisWorldSpace,
        int256[3][3][] memory trisCols,
        int256 canvasDim
    ) external view returns (int256[12][3][] memory) {
        /// make an array containing the fragments of each triangle (groups of 3 frags)
        int256[12][3][] memory trisFragments = new int256[12][3][](
            trisCameraSpace.length
        );

        // First convert from camera space to screen space within each triangle
        for (uint256 t = 0; t < trisCameraSpace.length; t++) {
            int256[3][3] memory tri = trisCameraSpace[t];

            /// initialise an array for three fragments, each of len 9
            int256[12][3] memory triFragments;

            // First calculate the fragments that belong to defined vertices
            for (uint256 v = 0; v < 3; v++) {
                int256[12] memory fragment;

                // first convert to screen space
                // mapping from -1e3 -> 1e3 to account for the original geom being on order of 1e3
                fragment[0] = ShackledMath.mapRangeToRange(
                    tri[v][0],
                    -1e3,
                    1e3,
                    0,
                    canvasDim
                );
                fragment[1] = ShackledMath.mapRangeToRange(
                    tri[v][1],
                    -1e3,
                    1e3,
                    0,
                    canvasDim
                );

                fragment[2] = tri[v][2];

                // Now calculate the normal using the cross product of the edge vectors. This needs to be
                // done in world space coordinates
                int256[3] memory thisV = trisWorldSpace[t][(v + 0) % 3];
                int256[3] memory nextV = trisWorldSpace[t][(v + 1) % 3];
                int256[3] memory prevV = trisWorldSpace[t][(v + 2) % 3];

                int256[3] memory norm = ShackledMath.crossProduct(
                    ShackledMath.vector3Sub(prevV, thisV),
                    ShackledMath.vector3Sub(thisV, nextV)
                );

                // Now attach the colour (in 0 -> 255 space)
                fragment[3] = (trisCols[t][v][0]);
                fragment[4] = (trisCols[t][v][1]);
                fragment[5] = (trisCols[t][v][2]);

                // And the normal (inverted)
                fragment[6] = -norm[0];
                fragment[7] = -norm[1];
                fragment[8] = -norm[2];

                // And the world position of this vertex to the frag
                fragment[9] = thisV[0];
                fragment[10] = thisV[1];
                fragment[11] = thisV[2];

                // These are just the fragments attached to
                // the given vertices
                triFragments[v] = fragment;
            }

            trisFragments[t] = triFragments;
        }

        return trisFragments;
    }

    /** @dev rasterize fragments onto a canvas
     */
    function rasterise(
        int256[12][3][] memory trisFragments,
        int256 canvasDim,
        bool wireframe
    ) external view returns (int256[12][] memory) {
        /// determine the upper limits of the inner Bresenham's result
        uint256 canvasHypot = uint256(ShackledMath.hypot(canvasDim, canvasDim));

        /// initialise a new array
        /// for each trisFragments we will get 3 results from bresenhams
        /// maximum of 1 per pixel (canvasDim**2)
        int256[12][] memory fragments = new int256[12][](
            3 * uint256(canvasDim)**2
        );
        uint256 nextFragmentsIx = 0;

        for (uint256 t = 0; t < trisFragments.length; t++) {
            // prepare the variables required
            int256[12] memory fa;
            int256[12] memory fb;
            uint256 nextBresTriFragmentIx = 0;

            /// create an array to hold the bresenham results
            /// this may cause an out of bounds error if there are a very large number of fragments
            /// (e.g. many that are 'off screen')
            int256[12][] memory bresTriFragments = new int256[12][](
                canvasHypot * 10
            );

            // for each pair of fragments, run bresenhams and extend bresTriFragments with the output
            // this replaces the three push(...modified_bresenhams_algorhtm) statements in JS
            for (uint256 i = 0; i < 3; i++) {
                if (i == 0) {
                    fa = trisFragments[t][0];
                    fb = trisFragments[t][1];
                } else if (i == 1) {
                    fa = trisFragments[t][1];
                    fb = trisFragments[t][2];
                } else {
                    fa = trisFragments[t][2];
                    fb = trisFragments[t][0];
                }

                // run the bresenhams algorithm
                (
                    bresTriFragments,
                    nextBresTriFragmentIx
                ) = runBresenhamsAlgorithm(
                    fa,
                    fb,
                    canvasDim,
                    bresTriFragments,
                    nextBresTriFragmentIx
                );
            }

            bresTriFragments = ShackledUtils.clipArray12ToLength(
                bresTriFragments,
                nextBresTriFragmentIx
            );

            if (wireframe) {
                /// only store the edges
                for (uint256 j = 0; j < bresTriFragments.length; j++) {
                    fragments[nextFragmentsIx] = bresTriFragments[j];
                    nextFragmentsIx++;
                }
            } else {
                /// fill the triangle
                (fragments, nextFragmentsIx) = runScanline(
                    bresTriFragments,
                    fragments,
                    nextFragmentsIx,
                    canvasDim
                );
            }
        }

        fragments = ShackledUtils.clipArray12ToLength(
            fragments,
            nextFragmentsIx
        );

        return fragments;
    }

    /** @dev run Bresenham's line algorithm on a pair of fragments
     */
    function runBresenhamsAlgorithm(
        int256[12] memory f1,
        int256[12] memory f2,
        int256 canvasDim,
        int256[12][] memory bresTriFragments,
        uint256 nextBresTriFragmentIx
    ) internal view returns (int256[12][] memory, uint256) {
        /// initiate a new set of vars
        BresenhamsVars memory vars;

        int256[12] memory fa;
        int256[12] memory fb;

        /// determine which fragment has a greater magnitude
        /// and set it as the destination (always order a given pair of edges the same)
        if (
            (f1[0]**2 + f1[1]**2 + f1[2]**2) < (f2[0]**2 + f2[1]**2 + f2[2]**2)
        ) {
            fa = f1;
            fb = f2;
        } else {
            fa = f2;
            fb = f1;
        }

        vars.x = fa[0];
        vars.y = fa[1];

        vars.dx = ShackledMath.abs(fb[0] - fa[0]);
        vars.dy = -ShackledMath.abs(fb[1] - fa[1]);
        int256 mag = ShackledMath.hypot(vars.dx, -vars.dy);

        if (fa[0] < fb[0]) {
            vars.sx = 1;
        } else {
            vars.sx = -1;
        }

        if (fa[1] < fb[1]) {
            vars.sy = 1;
        } else {
            vars.sy = -1;
        }

        vars.err = vars.dx + vars.dy;
        vars.e2 = 0;

        // get the bresenhams output for this fragment pair (fa & fb)

        if (mag == 0) {
            bresTriFragments[nextBresTriFragmentIx] = fa;
            bresTriFragments[nextBresTriFragmentIx + 1] = fb;
            nextBresTriFragmentIx += 2;
        } else {
            // when mag is not 0,
            // the length of the result will be max of upperLimitInner
            // but will be clipped to remove any empty slots
            (bresTriFragments, nextBresTriFragmentIx) = bresenhamsInner(
                vars,
                mag,
                fa,
                fb,
                canvasDim,
                bresTriFragments,
                nextBresTriFragmentIx
            );
        }
        return (bresTriFragments, nextBresTriFragmentIx);
    }

    /** @dev run the inner loop of Bresenham's line algorithm on a pair of fragments
     * (preventing stack too deep)
     */
    function bresenhamsInner(
        BresenhamsVars memory vars,
        int256 mag,
        int256[12] memory fa,
        int256[12] memory fb,
        int256 canvasDim,
        int256[12][] memory bresTriFragments,
        uint256 nextBresTriFragmentIx
    ) internal view returns (int256[12][] memory, uint256) {
        // define variables to be used in the inner loop
        int256 ir;
        int256 h;

        /// loop through all fragments
        while (!(vars.x == fb[0] && vars.y == fb[1])) {
            /// get hypotenuse length of fragment a
            h = ShackledMath.hypot(fa[0] - vars.x, fa[1] - vars.y);
            assembly {
                ir := div(mul(lerpScaleFactor, h), mag)
            }

            // only add the fragment if it falls within the canvas

            /// create a new fragment by linear interpolation between a and b
            int256[12] memory newFragment = ShackledMath.vector12Lerp(
                fa,
                fb,
                ir,
                lerpScaleFactor
            );
            newFragment[0] = vars.x;
            newFragment[1] = vars.y;

            /// save this fragment
            bresTriFragments[nextBresTriFragmentIx] = newFragment;
            ++nextBresTriFragmentIx;

            /// update variables to use in next iteration
            vars.e2 = 2 * vars.err;
            if (vars.e2 >= vars.dy) {
                vars.err += vars.dy;
                vars.x += vars.sx;
            }
            if (vars.e2 <= vars.dx) {
                vars.err += vars.dx;
                vars.y += vars.sy;
            }
        }

        /// save fragment 2
        bresTriFragments[nextBresTriFragmentIx] = fb;
        ++nextBresTriFragmentIx;

        return (bresTriFragments, nextBresTriFragmentIx);
    }

    /** @dev run the scan line algorithm to fill the raster
     */
    function runScanline(
        int256[12][] memory bresTriFragments,
        int256[12][] memory fragments,
        uint256 nextFragmentsIx,
        int256 canvasDim
    ) internal view returns (int256[12][] memory, uint256) {
        /// make a 2d array with length = num of output rows

        (
            int256[][] memory rowFragIndices,
            uint256[] memory nextIxFragRows
        ) = getRowFragIndices(bresTriFragments, canvasDim);

        /// initialise a struct to hold the scanline vars
        ScanlineVars memory slVars;

        // Now iterate through the list of fragments that live in a single row
        for (uint256 i = 0; i < rowFragIndices.length; i++) {
            /// Get the left most fragment
            slVars.left = 4096;

            /// Get the right most fragment
            slVars.right = -4096;

            /// loop through the fragments in this row
            /// and check that a fragment was written to this row
            for (uint256 j = 0; j < nextIxFragRows[i]; j++) {
                /// What's the current fragment that we're looking at
                int256 fragX = bresTriFragments[uint256(rowFragIndices[i][j])][
                    0
                ];

                // if it's lefter than our current most left frag then its the new left frag
                if (fragX < slVars.left) {
                    slVars.left = fragX;
                    slVars.leftFrag = bresTriFragments[
                        uint256(rowFragIndices[i][j])
                    ];
                }
                // if it's righter than our current most right frag then its the new right frag
                if (fragX > slVars.right) {
                    slVars.right = fragX;
                    slVars.rightFrag = bresTriFragments[
                        uint256(rowFragIndices[i][j])
                    ];
                }
            }

            /// now we need to scan from the left to the right fragment
            /// and interpolate as we go
            slVars.dx = slVars.right - slVars.left + 1;

            /// get the row that we're on
            slVars.newFragRow = slVars.leftFrag[1];

            /// check that the new frag's row will be in the canvas bounds
            if (slVars.newFragRow >= 0 && slVars.newFragRow < canvasDim) {
                if (slVars.dx > int256(0)) {
                    for (int256 j = 0; j < slVars.dx; j++) {
                        /// calculate the column of the new fragment (its position in the scan)
                        slVars.newFragCol = slVars.leftFrag[0] + j;

                        /// check that the new frag's column will be in the canvas bounds
                        if (
                            slVars.newFragCol >= 0 &&
                            slVars.newFragCol < canvasDim
                        ) {
                            slVars.ir = (j * lerpScaleFactor) / slVars.dx;

                            /// make a new fragment by linear interpolation between left and right frags
                            fragments[nextFragmentsIx] = ShackledMath
                                .vector12Lerp(
                                    slVars.leftFrag,
                                    slVars.rightFrag,
                                    slVars.ir,
                                    lerpScaleFactor
                                );
                            /// update its position
                            fragments[nextFragmentsIx][0] = slVars.newFragCol;
                            fragments[nextFragmentsIx][1] = slVars.newFragRow;
                            nextFragmentsIx++;
                        }
                    }
                }
            }
        }

        return (fragments, nextFragmentsIx);
    }

    /** @dev get the row indices of each fragment in preparation for the scanline alg
     */
    function getRowFragIndices(
        int256[12][] memory bresTriFragments,
        int256 canvasDim
    )
        internal
        view
        returns (int256[][] memory, uint256[] memory nextIxFragRows)
    {
        uint256 canvasDimUnsigned = uint256(canvasDim);

        // define the length of each outer array so we can push items into it using nextIxFragRows
        int256[][] memory rowFragIndices = new int256[][](canvasDimUnsigned);

        // the inner rows can't be longer than bresTriFragments
        for (uint256 i = 0; i < canvasDimUnsigned; i++) {
            rowFragIndices[i] = new int256[](bresTriFragments.length);
        }

        // make an array the tracks for each row how many items have been pushed into it
        uint256[] memory nextIxFragRows = new uint256[](canvasDimUnsigned);

        for (uint256 f = 0; f < bresTriFragments.length; f++) {
            // get the row index
            uint256 rowIx = uint256(bresTriFragments[f][1]); // canvas_y

            if (rowIx >= 0 && rowIx < canvasDimUnsigned) {
                // get the ix of the next item to be added to the row

                rowFragIndices[rowIx][nextIxFragRows[rowIx]] = int256(f);
                ++nextIxFragRows[rowIx];
            }
        }
        return (rowFragIndices, nextIxFragRows);
    }

    /** @dev run depth-testing on all fragments
     */
    function depthTesting(int256[12][] memory fragments, int256 canvasDim)
        external
        view
        returns (int256[12][] memory)
    {
        uint256 canvasDimUnsigned = uint256(canvasDim);
        /// create a 2d array to hold the zValues of the fragments
        int256[][] memory zValues = ShackledMath.get2dArray(
            canvasDimUnsigned,
            canvasDimUnsigned,
            0
        );

        /// create a 2d array to hold the fragIndex of the fragments
        /// as their depth is compared
        int256[][] memory fragIndex = ShackledMath.get2dArray(
            canvasDimUnsigned,
            canvasDimUnsigned,
            -1 /// -1 so we can check if a fragment was written to this location
        );

        int256[12][] memory culledFrags = new int256[12][](fragments.length);
        uint256 nextFragIx = 0;

        /// iterate through all fragments
        /// and store the index of the fragment with the largest z value
        /// at each x, y coordinate

        for (uint256 i = 0; i < fragments.length; i++) {
            int256[12] memory frag = fragments[i];

            /// x and y must be uint for indexing
            uint256 fragX = uint256(frag[0]);
            uint256 fragY = uint256(frag[1]);

            // console.log("checking frag", i, "z:");
            // console.logInt(frag[2]);

            if (
                (fragX < canvasDimUnsigned) &&
                (fragY < canvasDimUnsigned) &&
                fragX >= 0 &&
                fragY >= 0
            ) {
                // if this is the first fragment seen at (fragX, fragY), ie if fragIndex == 0, add it
                // or if this frag is closer (lower z value) than the current frag at (fragX, fragY), add it
                if (
                    fragIndex[fragX][fragY] == -1 ||
                    frag[2] >= zValues[fragX][fragY]
                ) {
                    zValues[fragX][fragY] = frag[2];
                    fragIndex[fragX][fragY] = int256(i);
                }
            }
        }

        /// save only the fragments with prefered z values
        for (uint256 x = 0; x < canvasDimUnsigned; x++) {
            for (uint256 y = 0; y < canvasDimUnsigned; y++) {
                int256 fragIx = fragIndex[x][y];
                /// ensure we have a valid index
                if (fragIndex[x][y] != -1) {
                    culledFrags[nextFragIx] = fragments[uint256(fragIx)];
                    nextFragIx++;
                }
            }
        }

        return ShackledUtils.clipArray12ToLength(culledFrags, nextFragIx);
    }

    /** @dev apply lighting to the scene and update fragments accordingly
     */
    function lightScene(
        int256[12][] memory fragments,
        ShackledStructs.LightingParams memory lp
    ) external view returns (int256[12][] memory) {
        /// create a struct for the variables to prevent stack too deep
        LightingVars memory lv;

        // calculate a constant lighting vector and its magniture
        lv.L = lp.lightPos;
        lv.lMag = ShackledMath.vector3Len(lv.L);

        for (uint256 f = 0; f < fragments.length; f++) {
            /// get the fragment's color, norm and position
            lv.fragCol = [fragments[f][3], fragments[f][4], fragments[f][5]];
            lv.fragNorm = [fragments[f][6], fragments[f][7], fragments[f][8]];
            lv.fragPos = [fragments[f][9], fragments[f][10], fragments[f][11]];

            /// calculate the direction to camera / viewer and its magnitude
            lv.V = ShackledMath.vector3MulScalar(lv.fragPos, -1);
            lv.vMag = ShackledMath.vector3Len(lv.V);

            /// calculate the direction of the fragment normaland its magnitude
            lv.N = lv.fragNorm;
            lv.nMag = ShackledMath.vector3Len(lv.N);

            /// calculate the light vector per-fragment
            // lv.L = ShackledMath.vector3Sub(lp.lightPos, lv.fragPos);
            // lv.lMag = ShackledMath.vector3Len(lv.L);
            lv.falloff = lv.lMag**2; /// lighting intensity fall over the scene
            lv.lnDot = ShackledMath.vector3Dot(lv.L, lv.N);

            /// implement double-side rendering to account for flipped normals
            lv.lambertian = ShackledMath.abs(lv.lnDot);

            int256 specular;

            if (lv.lambertian > 0) {
                int256[3] memory normedL = ShackledMath.vector3NormX(
                    lv.L,
                    fidelity
                );
                int256[3] memory normedV = ShackledMath.vector3NormX(
                    lv.V,
                    fidelity
                );

                int256[3] memory H = ShackledMath.vector3Add(normedL, normedV);

                int256 hnDot = int256(
                    ShackledMath.vector3Dot(
                        ShackledMath.vector3NormX(H, fidelity),
                        ShackledMath.vector3NormX(lv.N, fidelity)
                    )
                );

                specular = calculateSpecular(
                    lp.lightSpecPower,
                    hnDot,
                    fidelity,
                    lp.inverseShininess
                );
            }

            // Calculate the colour and write it into the fragment
            int256[3] memory colAmbi = ShackledMath.vector3Add(
                lv.fragCol,
                ShackledMath.vector3MulScalar(
                    lp.lightColAmbi,
                    lp.lightAmbiPower
                )
            );

            /// finalise and color the diffuse lighting
            int256[3] memory colDiff = ShackledMath.vector3MulScalar(
                lp.lightColDiff,
                ((lp.lightDiffPower * lv.lambertian) / (lv.lMag * lv.nMag)) /
                    lv.falloff
            );

            /// finalise and color the specular lighting
            int256[3] memory colSpec = ShackledMath.vector3DivScalar(
                ShackledMath.vector3MulScalar(lp.lightColSpec, specular),
                lv.falloff
            );

            // add up the colour components
            int256[3] memory col = ShackledMath.vector3Add(
                ShackledMath.vector3Add(colAmbi, colDiff),
                colSpec
            );

            /// update the fragment's colour in place
            fragments[f][3] = col[0];
            fragments[f][4] = col[1];
            fragments[f][5] = col[2];
        }
        return fragments;
    }

    /** @dev calculate the specular lighting parameter */
    function calculateSpecular(
        int256 lightSpecPower,
        int256 hnDot,
        int256 fidelity,
        uint256 inverseShininess
    ) internal pure returns (int256 specular) {
        int256 specAngle = hnDot > int256(0) ? hnDot : int256(0);
        assembly {
            specular := sdiv(
                mul(lightSpecPower, exp(specAngle, inverseShininess)),
                exp(fidelity, mul(inverseShininess, 2))
            )
        }
    }

    /** @dev get background gradient that fills the canvas */
    function getBackground(
        int256 canvasDim,
        int256[3][2] memory backgroundColor
    ) external view returns (int256[5][] memory) {
        int256[5][] memory background = new int256[5][](uint256(canvasDim**2));

        int256 w = canvasDim;
        uint256 nextIx = 0;

        for (int256 i = 0; i < canvasDim; i++) {
            for (int256 j = 0; j < canvasDim; j++) {
                // / write coordinates of background pixel
                background[nextIx][0] = j; /// x
                background[nextIx][1] = i; /// y

                // / write colours of background pixel
                // / get weighted average of top and bottom color according to row (i)
                background[nextIx][2] = /// r
                    ((backgroundColor[0][0] * i) +
                        (backgroundColor[1][0] * (w - i))) /
                    w;

                background[nextIx][3] = /// g
                    ((backgroundColor[0][1] * i) +
                        (backgroundColor[1][1] * (w - i))) /
                    w;

                background[nextIx][4] = /// b
                    ((backgroundColor[0][2] * i) +
                        (backgroundColor[1][2] * (w - i))) /
                    w;

                ++nextIx;
            }
        }
        return background;
    }
}