// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ShackledStructs.sol";
import "./ShackledMath.sol";
import "./Trigonometry.sol";

/* 
dir codes:
    0: right-left
    1: left-right
    2: up-down
    3: down-up

 sel codes:
    0: random
    1: biggest-first
    2: smallest-first
*/

library ShackledGenesis {
    uint256 constant MAX_N_ATTEMPTS = 150; // max number of attempts to find a valid triangle
    int256 constant ROT_XY_MAX = 12; // max amount of rotation in xy plane
    int256 constant MAX_CANVAS_SIZE = 32000; // max size of canvas

    /// a struct to hold vars in makeFacesVertsCols() to prevent StackTooDeep
    struct FacesVertsCols {
        uint256[3][] faces;
        int256[3][] verts;
        int256[3][] cols;
        uint256 nextColIdx;
        uint256 nextVertIdx;
        uint256 nextFaceIdx;
    }

    /** @dev generate all parameters required for the shackled renderer from a seed hash
    @param tokenHash a hash of the tokenId to be used in 'random' number generation
    */
    function generateGenesisPiece(bytes32 tokenHash)
        external
        view
        returns (
            ShackledStructs.RenderParams memory renderParams,
            ShackledStructs.Metadata memory metadata
        )
    {
        /// initial model paramaters
        renderParams.objScale = 1;
        renderParams.objPosition = [int256(0), 0, -2500];

        /// generate the geometry and colors
        (
            FacesVertsCols memory vars,
            ColorUtils.ColScheme memory colScheme,
            GeomUtils.GeomSpec memory geomSpec,
            GeomUtils.GeomVars memory geomVars
        ) = generateGeometryAndColors(tokenHash, renderParams.objPosition);

        renderParams.faces = vars.faces;
        renderParams.verts = vars.verts;
        renderParams.cols = vars.cols;

        /// use a perspective camera
        renderParams.perspCamera = true;

        if (geomSpec.id == 3) {
            renderParams.wireframe = false;
            renderParams.backfaceCulling = true;
        } else {
            /// determine wireframe trait (5% chance)
            if (GeomUtils.randN(tokenHash, "wireframe", 1, 100) > 95) {
                renderParams.wireframe = true;
                renderParams.backfaceCulling = false;
            } else {
                renderParams.wireframe = false;
                renderParams.backfaceCulling = true;
            }
        }

        if (
            colScheme.id == 2 ||
            colScheme.id == 3 ||
            colScheme.id == 7 ||
            colScheme.id == 8
        ) {
            renderParams.invert = false;
        } else {
            /// inversion (40% chance)
            renderParams.invert =
                GeomUtils.randN(tokenHash, "invert", 1, 10) > 6;
        }

        /// background colors
        renderParams.backgroundColor = [
            colScheme.bgColTop,
            colScheme.bgColBottom
        ];

        /// lighting parameters
        renderParams.lightingParams = ShackledStructs.LightingParams({
            applyLighting: true,
            lightAmbiPower: 0,
            lightDiffPower: 2000,
            lightSpecPower: 3000,
            inverseShininess: 10,
            lightColSpec: colScheme.lightCol,
            lightColDiff: colScheme.lightCol,
            lightColAmbi: colScheme.lightCol,
            lightPos: [int256(-50), 0, 0]
        });

        /// create the metadata
        metadata.colorScheme = colScheme.name;
        metadata.geomSpec = geomSpec.name;
        metadata.nPrisms = geomVars.nPrisms;

        if (geomSpec.isSymmetricX) {
            if (geomSpec.isSymmetricY) {
                metadata.pseudoSymmetry = "Diagonal";
            } else {
                metadata.pseudoSymmetry = "Horizontal";
            }
        } else if (geomSpec.isSymmetricY) {
            metadata.pseudoSymmetry = "Vertical";
        } else {
            metadata.pseudoSymmetry = "Scattered";
        }

        if (renderParams.wireframe) {
            metadata.wireframe = "Enabled";
        } else {
            metadata.wireframe = "Disabled";
        }

        if (renderParams.invert) {
            metadata.inversion = "Enabled";
        } else {
            metadata.inversion = "Disabled";
        }
    }

    /** @dev run a generative algorithm to create 3d geometries (prisms) and colors to render with Shackled
    also returns the faces and verts, which can be used to build a .obj file for in-browser rendering
     */
    function generateGeometryAndColors(
        bytes32 tokenHash,
        int256[3] memory objPosition
    )
        internal
        view
        returns (
            FacesVertsCols memory vars,
            ColorUtils.ColScheme memory colScheme,
            GeomUtils.GeomSpec memory geomSpec,
            GeomUtils.GeomVars memory geomVars
        )
    {
        /// get this geom's spec
        geomSpec = GeomUtils.generateSpec(tokenHash);

        /// create the triangles
        (
            int256[3][3][] memory tris,
            int256[] memory zFronts,
            int256[] memory zBacks
        ) = create2dTris(tokenHash, geomSpec);

        /// prismify
        geomVars = prismify(tokenHash, tris, zFronts, zBacks);

        /// generate colored faces
        /// get a color scheme
        colScheme = ColorUtils.getScheme(tokenHash, tris);

        /// get faces, verts and colors
        vars = makeFacesVertsCols(
            tokenHash,
            tris,
            geomVars,
            colScheme,
            objPosition
        );
    }

    /** @dev 'randomly' create an array of 2d triangles that will define each eventual 3d prism  */
    function create2dTris(bytes32 tokenHash, GeomUtils.GeomSpec memory geomSpec)
        internal
        view
        returns (
            int256[3][3][] memory, /// tris
            int256[] memory, /// zFronts
            int256[] memory /// zBacks
        )
    {
        /// initiate vars that will be used to store the triangle info
        GeomUtils.TriVars memory triVars;
        triVars.tris = new int256[3][3][]((geomSpec.maxPrisms + 5) * 2);
        triVars.zFronts = new int256[]((geomSpec.maxPrisms + 5) * 2);
        triVars.zBacks = new int256[]((geomSpec.maxPrisms + 5) * 2);

        /// 'randomly' initiate the starting radius
        int256 initialSize;

        if (geomSpec.forceInitialSize == 0) {
            initialSize = GeomUtils.randN(
                tokenHash,
                "size",
                geomSpec.minTriRad,
                geomSpec.maxTriRad
            );
        } else {
            initialSize = geomSpec.forceInitialSize;
        }

        /// 50% chance of 30deg rotation, 50% chance of 210deg rotation
        int256 initialRot = GeomUtils.randN(tokenHash, "rot", 0, 1) == 0
            ? int256(30)
            : int256(210);

        /// create the first triangle
        int256[3][3] memory currentTri = GeomUtils.makeTri(
            [int256(0), 0, 0],
            initialSize,
            initialRot
        );

        /// save it
        triVars.tris[0] = currentTri;

        /// calculate the first triangle's zs
        triVars.zBacks[0] = GeomUtils.calculateZ(
            currentTri,
            tokenHash,
            triVars.nextTriIdx,
            geomSpec,
            false
        );
        triVars.zFronts[0] = GeomUtils.calculateZ(
            currentTri,
            tokenHash,
            triVars.nextTriIdx,
            geomSpec,
            true
        );

        /// get the position to add the next triangle

        if (geomSpec.isSymmetricY) {
            /// override the first tri, since it is not symmetrical
            /// but temporarily save it as its needed as a reference tri
            triVars.nextTriIdx = 0;
        } else {
            triVars.nextTriIdx = 1;
        }

        /// make new triangles
        for (uint256 i = 0; i < MAX_N_ATTEMPTS; i++) {
            /// get a reference to a previous triangle
            uint256 refIdx = uint256(
                GeomUtils.randN(
                    tokenHash,
                    string(abi.encodePacked("refIdx", i)),
                    0,
                    int256(triVars.nextTriIdx) - 1
                )
            );

            /// ensure that the 'random' number generated is different in each while loop
            /// by incorporating the nAttempts and nextTriIdx into the seed modifier
            if (
                GeomUtils.randN(
                    tokenHash,
                    string(abi.encodePacked("adj", i, triVars.nextTriIdx)),
                    0,
                    100
                ) <= geomSpec.probVertOpp
            ) {
                /// attempt to recursively add vertically opposite triangles
                triVars = GeomUtils.makeVerticallyOppositeTriangles(
                    tokenHash,
                    i, // attemptNum (to create unique random seeds)
                    refIdx,
                    triVars,
                    geomSpec,
                    -1,
                    -1,
                    0 // depth (to create unique random seeds within recursion)
                );
            } else {
                /// attempt to recursively add adjacent triangles
                triVars = GeomUtils.makeAdjacentTriangles(
                    tokenHash,
                    i, // attemptNum (to create unique random seeds)
                    refIdx,
                    triVars,
                    geomSpec,
                    -1,
                    -1,
                    0 // depth (to create unique random seeds within recursion)
                );
            }

            /// can't have this many triangles
            if (triVars.nextTriIdx >= geomSpec.maxPrisms) {
                break;
            }
        }

        /// clip all the arrays to the actual number of triangles
        triVars.tris = GeomUtils.clipTrisToLength(
            triVars.tris,
            triVars.nextTriIdx
        );
        triVars.zBacks = GeomUtils.clipZsToLength(
            triVars.zBacks,
            triVars.nextTriIdx
        );
        triVars.zFronts = GeomUtils.clipZsToLength(
            triVars.zFronts,
            triVars.nextTriIdx
        );

        return (triVars.tris, triVars.zBacks, triVars.zFronts);
    }

    /** @dev prismify the initial 2d triangles output */
    function prismify(
        bytes32 tokenHash,
        int256[3][3][] memory tris,
        int256[] memory zFronts,
        int256[] memory zBacks
    ) internal view returns (GeomUtils.GeomVars memory) {
        /// initialise a struct to hold the vars we need
        GeomUtils.GeomVars memory geomVars;

        /// record the num of prisms
        geomVars.nPrisms = uint256(tris.length);

        /// figure out what point to put in the middle
        geomVars.extents = GeomUtils.getExtents(tris); // mins[3], maxs[3]

        /// scale the tris to fit in the canvas
        geomVars.width = geomVars.extents[1][0] - geomVars.extents[0][0];
        geomVars.height = geomVars.extents[1][1] - geomVars.extents[0][1];
        geomVars.extent = ShackledMath.max(geomVars.width, geomVars.height);
        geomVars.scaleNum = 2000;

        /// multiple all tris by the scale, then divide by the extent
        for (uint256 i = 0; i < tris.length; i++) {
            tris[i] = [
                ShackledMath.vector3DivScalar(
                    ShackledMath.vector3MulScalar(
                        tris[i][0],
                        geomVars.scaleNum
                    ),
                    geomVars.extent
                ),
                ShackledMath.vector3DivScalar(
                    ShackledMath.vector3MulScalar(
                        tris[i][1],
                        geomVars.scaleNum
                    ),
                    geomVars.extent
                ),
                ShackledMath.vector3DivScalar(
                    ShackledMath.vector3MulScalar(
                        tris[i][2],
                        geomVars.scaleNum
                    ),
                    geomVars.extent
                )
            ];
        }

        /// we may like to do some rotation, this means we get the shapes in the middle
        /// arrow up, down, left, right

        // 50% chance of x, y rotation being positive or negative
        geomVars.rotX = (GeomUtils.randN(tokenHash, "rotX", 0, 1) == 0)
            ? ROT_XY_MAX
            : -ROT_XY_MAX;

        geomVars.rotY = (GeomUtils.randN(tokenHash, "rotY", 0, 1) == 0)
            ? ROT_XY_MAX
            : -ROT_XY_MAX;

        // 50% chance to z rotation being 0 or 30
        geomVars.rotZ = (GeomUtils.randN(tokenHash, "rotZ", 0, 1) == 0)
            ? int256(0)
            : int256(30);

        /// rotate all tris around facing (z) axis
        for (uint256 i = 0; i < tris.length; i++) {
            tris[i] = GeomUtils.triRotHelp(2, tris[i], geomVars.rotZ);
        }

        geomVars.trisBack = GeomUtils.copyTris(tris);
        geomVars.trisFront = GeomUtils.copyTris(tris);

        /// front triangles need to come forward, back triangles need to go back
        for (uint256 i = 0; i < tris.length; i++) {
            for (uint256 j = 0; j < 3; j++) {
                for (uint256 k = 0; k < 3; k++) {
                    if (k == 2) {
                        /// get the z values (make sure the scale is applied)
                        geomVars.trisFront[i][j][k] = zFronts[i];
                        geomVars.trisBack[i][j][k] = zBacks[i];
                    } else {
                        /// copy the x and y values
                        geomVars.trisFront[i][j][k] = tris[i][j][k];
                        geomVars.trisBack[i][j][k] = tris[i][j][k];
                    }
                }
            }
        }

        /// rotate - order is import here (must come after prism splitting, and is dependant on z rotation)
        if (geomVars.rotZ == 0) {
            /// x then y
            (geomVars.trisBack, geomVars.trisFront) = GeomUtils.triBfHelp(
                0,
                geomVars.trisBack,
                geomVars.trisFront,
                geomVars.rotX
            );
            (geomVars.trisBack, geomVars.trisFront) = GeomUtils.triBfHelp(
                1,
                geomVars.trisBack,
                geomVars.trisFront,
                geomVars.rotY
            );
        } else {
            /// y then x
            (geomVars.trisBack, geomVars.trisFront) = GeomUtils.triBfHelp(
                1,
                geomVars.trisBack,
                geomVars.trisFront,
                geomVars.rotY
            );
            (geomVars.trisBack, geomVars.trisFront) = GeomUtils.triBfHelp(
                0,
                geomVars.trisBack,
                geomVars.trisFront,
                geomVars.rotX
            );
        }

        return geomVars;
    }

    /** @dev create verts and faces out of the geom and get their colors */
    function makeFacesVertsCols(
        bytes32 tokenHash,
        int256[3][3][] memory tris,
        GeomUtils.GeomVars memory geomVars,
        ColorUtils.ColScheme memory scheme,
        int256[3] memory objPosition
    ) internal view returns (FacesVertsCols memory vars) {
        /// the tris defined thus far are those at the front of each prism
        /// we need to calculate how many tris will then be in the final prisms (3 sides have 2 tris each, plus the front tri, = 7)
        uint256 numTrisPrisms = tris.length * 7; /// 7 tris per 3D prism (not inc. back)

        vars.faces = new uint256[3][](numTrisPrisms); /// array that holds indexes of verts needed to make each final triangle
        vars.verts = new int256[3][](tris.length * 6); /// the vertices for all final triangles
        vars.cols = new int256[3][](tris.length * 6); /// 1 col per final tri
        vars.nextColIdx = 0;
        vars.nextVertIdx = 0;
        vars.nextFaceIdx = 0;

        /// get some number of highlight triangles
        geomVars.hltPrismIdx = ColorUtils.getHighlightPrismIdxs(
            tris,
            tokenHash,
            scheme.hltNum,
            scheme.hltVarCode,
            scheme.hltSelCode
        );

        int256[3][2] memory frontExtents = GeomUtils.getExtents(
            geomVars.trisFront
        ); // mins[3], maxs[3]
        int256[3][2] memory backExtents = GeomUtils.getExtents(
            geomVars.trisBack
        ); // mins[3], maxs[3]
        int256[3][2] memory meanExtents = [
            [
                (frontExtents[0][0] + backExtents[0][0]) / 2,
                (frontExtents[0][1] + backExtents[0][1]) / 2,
                (frontExtents[0][2] + backExtents[0][2]) / 2
            ],
            [
                (frontExtents[1][0] + backExtents[1][0]) / 2,
                (frontExtents[1][1] + backExtents[1][1]) / 2,
                (frontExtents[1][2] + backExtents[1][2]) / 2
            ]
        ];

        /// apply translations such that we're at the center
        geomVars.center = ShackledMath.vector3DivScalar(
            ShackledMath.vector3Add(meanExtents[0], meanExtents[1]),
            2
        );

        geomVars.center[2] = 0;

        for (uint256 i = 0; i < tris.length; i++) {
            int256[3][6] memory prismCols;
            ColorUtils.SubScheme memory subScheme = ColorUtils.inArray(
                geomVars.hltPrismIdx,
                i
            )
                ? scheme.hlt
                : scheme.pri;

            /// get the colors for the prism
            prismCols = ColorUtils.getColForPrism(
                tokenHash,
                geomVars.trisFront[i],
                subScheme,
                meanExtents
            );

            /// save the colors (6 per prism)
            for (uint256 j = 0; j < 6; j++) {
                vars.cols[vars.nextColIdx] = prismCols[j];
                vars.nextColIdx++;
            }

            /// add 3 points (back)
            for (uint256 j = 0; j < 3; j++) {
                vars.verts[vars.nextVertIdx] = [
                    geomVars.trisBack[i][j][0],
                    geomVars.trisBack[i][j][1],
                    -geomVars.trisBack[i][j][2] /// flip the Z
                ];
                vars.nextVertIdx += 1;
            }

            /// add 3 points (front)
            for (uint256 j = 0; j < 3; j++) {
                vars.verts[vars.nextVertIdx] = [
                    geomVars.trisFront[i][j][0],
                    geomVars.trisFront[i][j][1],
                    -geomVars.trisFront[i][j][2] /// flip the Z
                ];
                vars.nextVertIdx += 1;
            }

            /// create the faces
            uint256 ii = i * 6;

            /// the orders are all important here (back is not visible)

            /// front
            vars.faces[vars.nextFaceIdx] = [ii + 3, ii + 4, ii + 5];

            /// side 1 flat
            vars.faces[vars.nextFaceIdx + 1] = [ii + 4, ii + 3, ii + 0];
            vars.faces[vars.nextFaceIdx + 2] = [ii + 0, ii + 1, ii + 4];

            /// side 2 rhs
            vars.faces[vars.nextFaceIdx + 3] = [ii + 5, ii + 4, ii + 1];
            vars.faces[vars.nextFaceIdx + 4] = [ii + 1, ii + 2, ii + 5];

            /// side 3 lhs
            vars.faces[vars.nextFaceIdx + 5] = [ii + 2, ii + 0, ii + 3];
            vars.faces[vars.nextFaceIdx + 6] = [ii + 3, ii + 5, ii + 2];

            vars.nextFaceIdx += 7;
        }

        for (uint256 i = 0; i < vars.verts.length; i++) {
            vars.verts[i] = ShackledMath.vector3Sub(
                vars.verts[i],
                geomVars.center
            );
        }
    }
}

/** Hold some functions useful for coloring in the prisms  */
library ColorUtils {
    /// a struct to hold vars within the main color scheme
    /// which can be used for both highlight (hlt) an primar (pri) colors
    struct SubScheme {
        int256[3] colA; // either the entire solid color, or one side of the gradient
        int256[3] colB; // either the same as A (solid), or different (gradient)
        bool isInnerGradient; // whether the gradient spans the triangle (true) or canvas (false)
        int256 dirCode; // which direction should the gradient be interpolated
        int256[3] jiggle; // how much to randomly jiffle the color space
        bool isJiggleInner; // does each inner vertiex get a jiggle, or is it triangle wide
        int256[3] backShift; // how much to take off the back face colors
    }

    /// a struct for each piece's color scheme
    struct ColScheme {
        string name;
        uint256 id;
        /// the primary color
        SubScheme pri;
        /// the highlight color
        SubScheme hlt;
        /// remaining parameters (not common to hlt and pri)
        uint256 hltNum;
        int256 hltSelCode;
        int256 hltVarCode;
        /// other scene colors
        int256[3] lightCol;
        int256[3] bgColTop;
        int256[3] bgColBottom;
    }

    /** @dev calculate the color of a prism
    returns an array of 6 colors (for each vertex of a prism) 
     */
    function getColForPrism(
        bytes32 tokenHash,
        int256[3][3] memory triFront,
        SubScheme memory subScheme,
        int256[3][2] memory extents
    ) external view returns (int256[3][6] memory cols) {
        if (
            subScheme.colA[0] == subScheme.colB[0] &&
            subScheme.colA[1] == subScheme.colB[1] &&
            subScheme.colA[2] == subScheme.colB[2]
        ) {
            /// just use color A (as B is the same, so there's no gradient)
            for (uint256 i = 0; i < 6; i++) {
                cols[i] = copyColor(subScheme.colA);
            }
        } else {
            /// get the colors according to the direction code
            int256[3][3] memory triFrontCopy = GeomUtils.copyTri(triFront);
            int256[3][3] memory frontTriCols = applyDirHelp(
                triFrontCopy,
                subScheme.colA,
                subScheme.colB,
                subScheme.dirCode,
                subScheme.isInnerGradient,
                extents
            );

            /// write in the same front colors as the back colors
            for (uint256 i = 0; i < 3; i++) {
                cols[i] = copyColor(frontTriCols[i]);
                cols[i + 3] = copyColor(frontTriCols[i]);
            }
        }

        /// perform the jiggling
        int256[3] memory jiggle;

        if (!subScheme.isJiggleInner) {
            /// get one set of jiggle values to use for all colors created
            jiggle = getJiggle(subScheme.jiggle, tokenHash, 0);
        }

        for (uint256 i = 0; i < 6; i++) {
            if (subScheme.isJiggleInner) {
                // jiggle again per col to create
                // use the last jiggle res in the random seed to get diff jiggles for each prism
                jiggle = getJiggle(subScheme.jiggle, tokenHash, jiggle[0]);
            }

            /// convert to hsv prior to jiggle
            int256[3] memory colHsv = rgb2hsv(
                cols[i][0],
                cols[i][1],
                cols[i][2]
            );

            /// add the jiggle to the colors in hsv space
            colHsv[0] = colHsv[0] + jiggle[0];
            colHsv[1] = colHsv[1] + jiggle[1];
            colHsv[2] = colHsv[2] + jiggle[2];

            /// convert back to rgb
            int256[3] memory colRgb = hsv2rgb(colHsv[0], colHsv[1], colHsv[2]);
            cols[i][0] = colRgb[0];
            cols[i][1] = colRgb[1];
            cols[i][2] = colRgb[2];
        }

        /// perform back shifting
        for (uint256 i = 0; i < 3; i++) {
            cols[i][0] -= subScheme.backShift[0];
            cols[i][1] -= subScheme.backShift[1];
            cols[i][2] -= subScheme.backShift[2];
        }

        /// ensure that we're in 255 range
        for (uint256 i = 0; i < 6; i++) {
            cols[i][0] = ShackledMath.max(0, ShackledMath.min(255, cols[i][0]));
            cols[i][1] = ShackledMath.max(0, ShackledMath.min(255, cols[i][1]));
            cols[i][2] = ShackledMath.max(0, ShackledMath.min(255, cols[i][2]));
        }

        return cols;
    }

    /** @dev roll a schemeId given a list of weightings */
    function getSchemeId(bytes32 tokenHash, int256[2][10] memory weightings)
        internal
        view
        returns (uint256)
    {
        int256 n = GeomUtils.randN(
            tokenHash,
            "schemedId",
            weightings[0][0],
            weightings[weightings.length - 1][1]
        );
        for (uint256 i = 0; i < weightings.length; i++) {
            if (weightings[i][0] <= n && n <= weightings[i][1]) {
                return i;
            }
        }
    }

    /** @dev make a copy of a color */
    function copyColor(int256[3] memory c)
        internal
        view
        returns (int256[3] memory)
    {
        return [c[0], c[1], c[2]];
    }

    /** @dev get a color scheme */
    function getScheme(bytes32 tokenHash, int256[3][3][] memory tris)
        external
        view
        returns (ColScheme memory colScheme)
    {
        /// 'randomly' select 1 of the 9 schemes
        uint256 schemeId = getSchemeId(
            tokenHash,
            [
                [int256(0), 1500],
                [int256(1500), 2500],
                [int256(2500), 3000],
                [int256(3000), 3100],
                [int256(3100), 5500],
                [int256(5500), 6000],
                [int256(6000), 6500],
                [int256(6500), 8000],
                [int256(8000), 9500],
                [int256(9500), 10000]
            ]
        );

        // int256 schemeId = GeomUtils.randN(tokenHash, "schemeID", 1, 9);

        /// define the color scheme to use for this piece
        /// all arrays are on the order of 1000 to remain accurate as integers
        /// will require division by 1000 later when in use

        if (schemeId == 0) {
            /// plain / beigey with a highlight, and a matching background colour
            colScheme = ColScheme({
                name: "Accentuated",
                id: schemeId,
                pri: SubScheme({
                    colA: [int256(60), 30, 25],
                    colB: [int256(205), 205, 205],
                    isInnerGradient: false,
                    dirCode: 0,
                    jiggle: [int256(13), 13, 13],
                    isJiggleInner: false,
                    backShift: [int256(205), 205, 205]
                }),
                hlt: SubScheme({
                    colA: [int256(255), 0, 0],
                    colB: [int256(255), 50, 0],
                    isInnerGradient: true,
                    dirCode: GeomUtils.randN(tokenHash, "hltDir", 0, 3), /// get a 'random' dir code
                    jiggle: [int256(50), 50, 50],
                    isJiggleInner: false,
                    backShift: [int256(205), 205, 205]
                }),
                hltNum: uint256(GeomUtils.randN(tokenHash, "hltNum", 3, 5)), /// get a 'random' number of highlights between 3 and 5
                hltSelCode: 1, /// 'biggest' selection code
                hltVarCode: 0,
                lightCol: [int256(255), 255, 255],
                bgColTop: [int256(0), 0, 0],
                bgColBottom: [int256(1), 1, 1]
            });
        } else if (schemeId == 1) {
            /// neutral overall
            colScheme = ColScheme({
                name: "Emergent",
                id: schemeId,
                pri: SubScheme({
                    colA: [int256(0), 77, 255],
                    colB: [int256(0), 255, 25],
                    isInnerGradient: true,
                    dirCode: GeomUtils.randN(tokenHash, "priDir", 2, 3), /// get a 'random' dir code (2 or 3)
                    jiggle: [int256(60), 60, 60],
                    isJiggleInner: false,
                    backShift: [int256(-255), -255, -255]
                }),
                hlt: SubScheme({
                    colA: [int256(0), 77, 255],
                    colB: [int256(0), 255, 25],
                    isInnerGradient: true,
                    dirCode: 3,
                    jiggle: [int256(60), 60, 60],
                    isJiggleInner: false,
                    backShift: [int256(-255), -255, -255]
                }),
                hltNum: uint256(GeomUtils.randN(tokenHash, "hltNum", 4, 6)), /// get a 'random' number of highlights between 4 and 6
                hltSelCode: 2, /// smallest-first
                hltVarCode: 0,
                lightCol: [int256(255), 255, 255],
                bgColTop: [int256(255), 255, 255],
                bgColBottom: [int256(255), 255, 255]
            });
        } else if (schemeId == 2) {
            /// vaporwave
            int256 maxHighlights = ShackledMath.max(0, int256(tris.length) - 8);
            int256 minHighlights = ShackledMath.max(
                0,
                int256(maxHighlights) - 2
            );
            colScheme = ColScheme({
                name: "Sunset",
                id: schemeId,
                pri: SubScheme({
                    colA: [int256(179), 0, 179],
                    colB: [int256(0), 0, 255],
                    isInnerGradient: false,
                    dirCode: 2, /// up-down
                    jiggle: [int256(25), 25, 25],
                    isJiggleInner: true,
                    backShift: [int256(127), 127, 127]
                }),
                hlt: SubScheme({
                    colA: [int256(0), 0, 0],
                    colB: [int256(0), 0, 0],
                    isInnerGradient: true,
                    dirCode: 3, /// down-up
                    jiggle: [int256(15), 0, 15],
                    isJiggleInner: true,
                    backShift: [int256(0), 0, 0]
                }),
                hltNum: uint256(
                    GeomUtils.randN(
                        tokenHash,
                        "hltNum",
                        minHighlights,
                        maxHighlights
                    )
                ), /// get a 'random' number of highlights between minHighlights and maxHighlights
                hltSelCode: 2, /// smallest-first
                hltVarCode: 0,
                lightCol: [int256(255), 255, 255],
                bgColTop: [int256(250), 103, 247],
                bgColBottom: [int256(157), 104, 250]
            });
        } else if (schemeId == 3) {
            /// gold
            int256 priDirCode = GeomUtils.randN(tokenHash, "pirDir", 0, 1); /// get a 'random' dir code (0 or 1)
            colScheme = ColScheme({
                name: "Stone & Gold",
                id: schemeId,
                pri: SubScheme({
                    colA: [int256(50), 50, 50],
                    colB: [int256(100), 100, 100],
                    isInnerGradient: true,
                    dirCode: priDirCode,
                    jiggle: [int256(10), 10, 10],
                    isJiggleInner: true,
                    backShift: [int256(128), 128, 128]
                }),
                hlt: SubScheme({
                    colA: [int256(255), 197, 0],
                    colB: [int256(255), 126, 0],
                    isInnerGradient: true,
                    dirCode: priDirCode,
                    jiggle: [int256(0), 0, 0],
                    isJiggleInner: false,
                    backShift: [int256(64), 64, 64]
                }),
                hltNum: 1,
                hltSelCode: 1, /// biggest-first
                hltVarCode: 0,
                lightCol: [int256(255), 255, 255],
                bgColTop: [int256(0), 0, 0],
                bgColBottom: [int256(0), 0, 0]
            });
        } else if (schemeId == 4) {
            /// random pastel colors (sometimes black)
            /// for primary colors,
            /// follow the pattern of making a new and unique seedHash for each variable
            /// so they are independant
            /// seed modifiers = pri/hlt + a/b + /r/g/b
            colScheme = ColScheme({
                name: "Denatured",
                id: schemeId,
                pri: SubScheme({
                    colA: [
                        GeomUtils.randN(tokenHash, "PAR", 25, 255),
                        GeomUtils.randN(tokenHash, "PAG", 25, 255),
                        GeomUtils.randN(tokenHash, "PAB", 25, 255)
                    ],
                    colB: [
                        GeomUtils.randN(tokenHash, "PBR", 25, 255),
                        GeomUtils.randN(tokenHash, "PBG", 25, 255),
                        GeomUtils.randN(tokenHash, "PBB", 25, 255)
                    ],
                    isInnerGradient: false,
                    dirCode: GeomUtils.randN(tokenHash, "pri", 0, 1), /// get a 'random' dir code (0 or 1)
                    jiggle: [int256(0), 0, 0],
                    isJiggleInner: false,
                    backShift: [int256(127), 127, 127]
                }),
                hlt: SubScheme({
                    colA: [
                        GeomUtils.randN(tokenHash, "HAR", 25, 255),
                        GeomUtils.randN(tokenHash, "HAG", 25, 255),
                        GeomUtils.randN(tokenHash, "HAB", 25, 255)
                    ],
                    colB: [
                        GeomUtils.randN(tokenHash, "HBR", 25, 255),
                        GeomUtils.randN(tokenHash, "HBG", 25, 255),
                        GeomUtils.randN(tokenHash, "HBB", 25, 255)
                    ],
                    isInnerGradient: false,
                    dirCode: GeomUtils.randN(tokenHash, "hlt", 0, 1), /// get a 'random' dir code (0 or 1)
                    jiggle: [int256(0), 0, 0],
                    isJiggleInner: false,
                    backShift: [int256(127), 127, 127]
                }),
                hltNum: tris.length / 2,
                hltSelCode: 2, /// smallest-first
                hltVarCode: 0,
                lightCol: [int256(255), 255, 255],
                bgColTop: [int256(3), 3, 3],
                bgColBottom: [int256(0), 0, 0]
            });
        } else if (schemeId == 5) {
            /// inter triangle random colors ('chameleonic')

            /// pri dir code is anything (0, 1, 2, 3)
            /// hlt dir code is oppose to pri dir code (rl <-> lr, up <-> du)
            int256 priDirCode = GeomUtils.randN(tokenHash, "pri", 0, 3); /// get a 'random' dir code (0 or 1)
            int256 hltDirCode;
            if (priDirCode == 0 || priDirCode == 1) {
                hltDirCode = priDirCode == 0 ? int256(1) : int256(0);
            } else {
                hltDirCode = priDirCode == 2 ? int256(3) : int256(2);
            }
            /// for primary colors,
            /// follow the pattern of making a new and unique seedHash for each variable
            /// so they are independant
            /// seed modifiers = pri/hlt + a/b + /r/g/b
            colScheme = ColScheme({
                name: "Chameleonic",
                id: schemeId,
                pri: SubScheme({
                    colA: [
                        GeomUtils.randN(tokenHash, "PAR", 25, 255),
                        GeomUtils.randN(tokenHash, "PAG", 25, 255),
                        GeomUtils.randN(tokenHash, "PAB", 25, 255)
                    ],
                    colB: [
                        GeomUtils.randN(tokenHash, "PBR", 25, 255),
                        GeomUtils.randN(tokenHash, "PBG", 25, 255),
                        GeomUtils.randN(tokenHash, "PBB", 25, 255)
                    ],
                    isInnerGradient: true,
                    dirCode: priDirCode,
                    jiggle: [int256(25), 25, 25],
                    isJiggleInner: true,
                    backShift: [int256(0), 0, 0]
                }),
                hlt: SubScheme({
                    colA: [
                        GeomUtils.randN(tokenHash, "HAR", 25, 255),
                        GeomUtils.randN(tokenHash, "HAG", 25, 255),
                        GeomUtils.randN(tokenHash, "HAB", 25, 255)
                    ],
                    colB: [
                        GeomUtils.randN(tokenHash, "HBR", 25, 255),
                        GeomUtils.randN(tokenHash, "HBG", 25, 255),
                        GeomUtils.randN(tokenHash, "HBB", 25, 255)
                    ],
                    isInnerGradient: true,
                    dirCode: hltDirCode,
                    jiggle: [int256(255), 255, 255],
                    isJiggleInner: true,
                    backShift: [int256(205), 205, 205]
                }),
                hltNum: 12,
                hltSelCode: 2, /// smallest-first
                hltVarCode: 0,
                lightCol: [int256(255), 255, 255],
                bgColTop: [int256(3), 3, 3],
                bgColBottom: [int256(0), 0, 0]
            });
        } else if (schemeId == 6) {
            /// each prism is a different colour with some randomisation

            /// pri dir code is anything (0, 1, 2, 3)
            /// hlt dir code is oppose to pri dir code (rl <-> lr, up <-> du)
            int256 priDirCode = GeomUtils.randN(tokenHash, "pri", 0, 1); /// get a 'random' dir code (0 or 1)
            int256 hltDirCode;
            if (priDirCode == 0 || priDirCode == 1) {
                hltDirCode = priDirCode == 0 ? int256(1) : int256(0);
            } else {
                hltDirCode = priDirCode == 2 ? int256(3) : int256(2);
            }
            /// for primary colors,
            /// follow the pattern of making a new and unique seedHash for each variable
            /// so they are independant
            /// seed modifiers = pri/hlt + a/b + /r/g/b
            colScheme = ColScheme({
                name: "Gradiated",
                id: schemeId,
                pri: SubScheme({
                    colA: [
                        GeomUtils.randN(tokenHash, "PAR", 25, 255),
                        GeomUtils.randN(tokenHash, "PAG", 25, 255),
                        GeomUtils.randN(tokenHash, "PAB", 25, 255)
                    ],
                    colB: [
                        GeomUtils.randN(tokenHash, "PBR", 25, 255),
                        GeomUtils.randN(tokenHash, "PBG", 25, 255),
                        GeomUtils.randN(tokenHash, "PBB", 25, 255)
                    ],
                    isInnerGradient: false,
                    dirCode: priDirCode,
                    jiggle: [int256(127), 127, 127],
                    isJiggleInner: false,
                    backShift: [int256(205), 205, 205]
                }),
                hlt: SubScheme({
                    colA: [
                        GeomUtils.randN(tokenHash, "HAR", 25, 255),
                        GeomUtils.randN(tokenHash, "HAG", 25, 255),
                        GeomUtils.randN(tokenHash, "HAB", 25, 255)
                    ],
                    colB: [
                        GeomUtils.randN(tokenHash, "HBR", 25, 255),
                        GeomUtils.randN(tokenHash, "HBG", 25, 255),
                        GeomUtils.randN(tokenHash, "HBB", 25, 255)
                    ],
                    isInnerGradient: false,
                    dirCode: hltDirCode,
                    jiggle: [int256(127), 127, 127],
                    isJiggleInner: false,
                    backShift: [int256(205), 205, 205]
                }),
                hltNum: 12, /// get a 'random' number of highlights between 4 and 6
                hltSelCode: 2, /// smallest-first
                hltVarCode: 0,
                lightCol: [int256(255), 255, 255],
                bgColTop: [int256(3), 3, 3],
                bgColBottom: [int256(0), 0, 0]
            });
        } else if (schemeId == 7) {
            /// feature colour on white primary, with feature colour background
            /// calculate the feature color in hsv
            int256[3] memory hsv = [
                GeomUtils.randN(tokenHash, "hsv", 0, 255),
                230,
                255
            ];
            int256[3] memory hltColA = hsv2rgb(hsv[0], hsv[1], hsv[2]);

            colScheme = ColScheme({
                name: "Vivid Alabaster",
                id: schemeId,
                pri: SubScheme({
                    colA: [int256(255), 255, 255],
                    colB: [int256(255), 255, 255],
                    isInnerGradient: true,
                    dirCode: GeomUtils.randN(tokenHash, "pri", 0, 3), /// get a 'random' dir code (0 or 1)
                    jiggle: [int256(25), 25, 25],
                    isJiggleInner: true,
                    backShift: [int256(127), 127, 127]
                }),
                hlt: SubScheme({
                    colA: hltColA,
                    colB: copyColor(hltColA), /// same as A
                    isInnerGradient: true,
                    dirCode: GeomUtils.randN(tokenHash, "pri", 0, 3), /// same as priDirCode
                    jiggle: [int256(25), 50, 50],
                    isJiggleInner: true,
                    backShift: [int256(180), 180, 180]
                }),
                hltNum: tris.length % 2 == 1
                    ? (tris.length / 2) + 1
                    : tris.length / 2,
                hltSelCode: GeomUtils.randN(tokenHash, "hltSel", 0, 2),
                hltVarCode: 0,
                lightCol: [int256(255), 255, 255],
                bgColTop: hsv2rgb(
                    ShackledMath.mod((hsv[0] - 9), 255),
                    105,
                    255
                ),
                bgColBottom: hsv2rgb(
                    ShackledMath.mod((hsv[0] + 9), 255),
                    105,
                    255
                )
            });
        } else if (schemeId == 8) {
            /// feature colour on black primary, with feature colour background
            /// calculate the feature color in hsv
            int256[3] memory hsv = [
                GeomUtils.randN(tokenHash, "hsv", 0, 255),
                245,
                190
            ];

            int256[3] memory hltColA = hsv2rgb(hsv[0], hsv[1], hsv[2]);

            colScheme = ColScheme({
                name: "Vivid Ink",
                id: schemeId,
                pri: SubScheme({
                    colA: [int256(0), 0, 0],
                    colB: [int256(0), 0, 0],
                    isInnerGradient: true,
                    dirCode: GeomUtils.randN(tokenHash, "pri", 0, 3), /// get a 'random' dir code (0 or 1)
                    jiggle: [int256(25), 25, 25],
                    isJiggleInner: false,
                    backShift: [int256(-60), -60, -60]
                }),
                hlt: SubScheme({
                    colA: hltColA,
                    colB: copyColor(hltColA), /// same as A
                    isInnerGradient: true,
                    dirCode: GeomUtils.randN(tokenHash, "pri", 0, 3), /// same as priDirCode
                    jiggle: [int256(0), 0, 0],
                    isJiggleInner: false,
                    backShift: [int256(-60), -60, -60]
                }),
                hltNum: tris.length % 2 == 1
                    ? (tris.length / 2) + 1
                    : tris.length / 2,
                hltSelCode: GeomUtils.randN(tokenHash, "hltSel", 0, 2),
                hltVarCode: GeomUtils.randN(tokenHash, "hltVar", 0, 2),
                lightCol: [int256(255), 255, 255],
                bgColTop: hsv2rgb(
                    ShackledMath.mod((hsv[0] - 9), 255),
                    105,
                    255
                ),
                bgColBottom: hsv2rgb(
                    ShackledMath.mod((hsv[0] + 9), 255),
                    105,
                    255
                )
            });
        } else if (schemeId == 9) {
            colScheme = ColScheme({
                name: "Pigmented",
                id: schemeId,
                pri: SubScheme({
                    colA: [int256(50), 30, 25],
                    colB: [int256(205), 205, 205],
                    isInnerGradient: false,
                    dirCode: 0,
                    jiggle: [int256(13), 13, 13],
                    isJiggleInner: false,
                    backShift: [int256(205), 205, 205]
                }),
                hlt: SubScheme({
                    colA: [int256(255), 0, 0],
                    colB: [int256(255), 50, 0],
                    isInnerGradient: true,
                    dirCode: GeomUtils.randN(tokenHash, "hltDir", 0, 3), /// get a 'random' dir code
                    jiggle: [int256(255), 50, 50],
                    isJiggleInner: false,
                    backShift: [int256(205), 205, 205]
                }),
                hltNum: tris.length / 3,
                hltSelCode: 1, /// 'biggest' selection code
                hltVarCode: 0,
                lightCol: [int256(255), 255, 255],
                bgColTop: [int256(0), 0, 0],
                bgColBottom: [int256(7), 7, 7]
            });
        } else {
            revert("invalid scheme id");
        }

        return colScheme;
    }

    /** @dev convert hsv to rgb color
    assume h, s and v and in range [0, 255]
    outputs rgb in range [0, 255]
     */
    function hsv2rgb(
        int256 h,
        int256 s,
        int256 v
    ) internal view returns (int256[3] memory res) {
        /// ensure range 0, 255
        h = ShackledMath.max(0, ShackledMath.min(255, h));
        s = ShackledMath.max(0, ShackledMath.min(255, s));
        v = ShackledMath.max(0, ShackledMath.min(255, v));

        int256 h2 = (((h % 255) * 1e3) / 255) * 360; /// convert to degress
        int256 v2 = (v * 1e3) / 255;
        int256 s2 = (s * 1e3) / 255;

        /// calculate c, x and m while scaling all by 1e3
        /// otherwise x will be too small and round to 0
        int256 c = (v2 * s2) / 1e3;

        int256 x = (c *
            (1 * 1e3 - ShackledMath.abs(((h2 / 60) % (2 * 1e3)) - (1 * 1e3))));

        x = x / 1e3;

        int256 m = v2 - c;

        if (0 <= h2 && h2 < 60000) {
            res = [c + m, x + m, m];
        } else if (60000 <= h2 && h2 < 120000) {
            res = [x + m, c + m, m];
        } else if (120000 < h2 && h2 < 180000) {
            res = [m, c + m, x + m];
        } else if (180000 < h2 && h2 < 240000) {
            res = [m, x + m, c + m];
        } else if (240000 < h2 && h2 < 300000) {
            res = [x + m, m, c + m];
        } else if (300000 < h2 && h2 < 360000) {
            res = [c + m, m, x + m];
        } else {
            res = [int256(0), 0, 0];
        }

        /// scale into correct range
        return [
            (res[0] * 255) / 1e3,
            (res[1] * 255) / 1e3,
            (res[2] * 255) / 1e3
        ];
    }

    /** @dev convert rgb to hsv 
        expects rgb to be in range [0, 255]
        outputs hsv in range [0, 255]
    */
    function rgb2hsv(
        int256 r,
        int256 g,
        int256 b
    ) internal view returns (int256[3] memory) {
        int256 r2 = (r * 1e3) / 255;
        int256 g2 = (g * 1e3) / 255;
        int256 b2 = (b * 1e3) / 255;
        int256 max = ShackledMath.max(ShackledMath.max(r2, g2), b2);
        int256 min = ShackledMath.min(ShackledMath.min(r2, g2), b2);
        int256 delta = max - min;

        /// calculate hue
        int256 h;
        if (delta != 0) {
            if (max == r2) {
                int256 _h = ((g2 - b2) * 1e3) / delta;
                h = 60 * ShackledMath.mod(_h, 6000);
            } else if (max == g2) {
                h = 60 * (((b2 - r2) * 1e3) / delta + (2000));
            } else if (max == b2) {
                h = 60 * (((r2 - g2) * 1e3) / delta + (4000));
            }
        }

        h = (h % (360 * 1e3)) / 360;

        /// calculate saturation
        int256 s;
        if (max != 0) {
            s = (delta * 1e3) / max;
        }

        /// calculate value
        int256 v = max;

        return [(h * 255) / 1e3, (s * 255) / 1e3, (v * 255) / 1e3];
    }

    /** @dev get vector of three numbers that can be used to jiggle a color */
    function getJiggle(
        int256[3] memory jiggle,
        bytes32 randomSeed,
        int256 seedModifier
    ) internal view returns (int256[3] memory) {
        return [
            jiggle[0] +
                GeomUtils.randN(
                    randomSeed,
                    string(abi.encodePacked("0", seedModifier)),
                    -jiggle[0],
                    jiggle[0]
                ),
            jiggle[1] +
                GeomUtils.randN(
                    randomSeed,
                    string(abi.encodePacked("1", seedModifier)),
                    -jiggle[1],
                    jiggle[1]
                ),
            jiggle[2] +
                GeomUtils.randN(
                    randomSeed,
                    string(abi.encodePacked("2", seedModifier)),
                    -jiggle[2],
                    jiggle[2]
                )
        ];
    }

    /** @dev check if a uint is in an array */
    function inArray(uint256[] memory array, uint256 value)
        external
        view
        returns (bool)
    {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }

    /** @dev a helper function to apply the direction code in interpolation */
    function applyDirHelp(
        int256[3][3] memory triFront,
        int256[3] memory colA,
        int256[3] memory colB,
        int256 dirCode,
        bool isInnerGradient,
        int256[3][2] memory extents
    ) internal view returns (int256[3][3] memory triCols) {
        uint256[3] memory order;
        if (isInnerGradient) {
            /// perform the simple 3 sort - always color by the front
            order = getOrderedPointIdxsInDir(triFront, dirCode);
        } else {
            /// order irrelevant in other case
            order = [uint256(0), 1, 2];
        }

        /// axis is 0 (horizontal) if dir code is left-right or right-left
        /// 1 (vertical) otherwise
        uint256 axis = (dirCode == 0 || dirCode == 1) ? 0 : 1;

        int256 length;
        if (axis == 0) {
            length = extents[1][0] - extents[0][0];
        } else {
            length = extents[1][1] - extents[0][1];
        }

        /// if we're interpolating across the triangle (inner)
        /// then do so by calculating the color at each point in the triangle
        for (uint256 i = 0; i < 3; i++) {
            triCols[order[i]] = interpColHelp(
                colA,
                colB,
                (isInnerGradient)
                    ? triFront[order[0]][axis]
                    : int256(-length / 2),
                (isInnerGradient)
                    ? triFront[order[2]][axis]
                    : int256(length / 2),
                triFront[order[i]][axis]
            );
        }
    }

    /** @dev a helper function to order points by index in a desired direction
     */
    function getOrderedPointIdxsInDir(int256[3][3] memory tri, int256 dirCode)
        internal
        view
        returns (uint256[3] memory)
    {
        // flip if dir is left-right or down-up
        bool flip = (dirCode == 1 || dirCode == 3) ? true : false;

        // axis is 0 if horizontal (left-right or right-left), 1 otherwise (vertical)
        uint256 axis = (dirCode == 0 || dirCode == 1) ? 0 : 1;

        /// get the values of each point in the tri (flipped as required)
        int256 f = (flip) ? int256(-1) : int256(1);
        int256 a = f * tri[0][axis];
        int256 b = f * tri[1][axis];
        int256 c = f * tri[2][axis];

        /// get the ordered indices
        uint256[3] memory ixOrd = [uint256(0), 1, 2];

        /// simplest way to sort 3 numbers
        if (a > b) {
            (a, b) = (b, a);
            (ixOrd[0], ixOrd[1]) = (ixOrd[1], ixOrd[0]);
        }
        if (a > c) {
            (a, c) = (c, a);
            (ixOrd[0], ixOrd[2]) = (ixOrd[2], ixOrd[0]);
        }
        if (b > c) {
            (b, c) = (c, b);
            (ixOrd[1], ixOrd[2]) = (ixOrd[2], ixOrd[1]);
        }
        return ixOrd;
    }

    /** @dev a helper function for linear interpolation betweet two colors*/
    function interpColHelp(
        int256[3] memory colA,
        int256[3] memory colB,
        int256 low,
        int256 high,
        int256 val
    ) internal view returns (int256[3] memory result) {
        int256 ir;
        int256 lerpScaleFactor = 1e3;
        if (high - low == 0) {
            ir = 1;
        } else {
            ir = ((val - low) * lerpScaleFactor) / (high - low);
        }

        for (uint256 i = 0; i < 3; i++) {
            /// dont allow interpolation to go below 0
            result[i] = ShackledMath.max(
                0,
                colA[i] + ((colB[i] - colA[i]) * ir) / lerpScaleFactor
            );
        }
    }

    /** @dev get indexes of the prisms to use highlight coloring*/
    function getHighlightPrismIdxs(
        int256[3][3][] memory tris,
        bytes32 tokenHash,
        uint256 nHighlights,
        int256 varCode,
        int256 selCode
    ) internal view returns (uint256[] memory idxs) {
        nHighlights = nHighlights < tris.length ? nHighlights : tris.length;

        ///if we just want random triangles then there's no need to sort
        if (selCode == 0) {
            idxs = ShackledMath.randomIdx(
                tokenHash,
                uint256(nHighlights),
                tris.length - 1
            );
        } else {
            idxs = getSortedTrisIdxs(tris, nHighlights, varCode, selCode);
        }
    }

    /** @dev return the index of the tris sorted by sel code
    @param selCode will be 1 (biggest first) or 2 (smallest first)
    */
    function getSortedTrisIdxs(
        int256[3][3][] memory tris,
        uint256 nHighlights,
        int256 varCode,
        int256 selCode
    ) internal view returns (uint256[] memory) {
        // determine the sort order
        int256 orderFactor = (selCode == 2) ? int256(1) : int256(-1);
        /// get the list of triangle sizes
        int256[] memory sizes = new int256[](tris.length);
        for (uint256 i = 0; i < tris.length; i++) {
            if (varCode == 0) {
                // use size
                sizes[i] = GeomUtils.getRadiusLen(tris[i]) * orderFactor;
            } else if (varCode == 1) {
                // use x
                sizes[i] = GeomUtils.getCenterVec(tris[i])[0] * orderFactor;
            } else if (varCode == 2) {
                // use y
                sizes[i] = GeomUtils.getCenterVec(tris[i])[1] * orderFactor;
            }
        }
        /// initialise the index array
        uint256[] memory idxs = new uint256[](tris.length);
        for (uint256 i = 0; i < tris.length; i++) {
            idxs[i] = i;
        }
        /// run a boilerplate insertion sort over the index array
        for (uint256 i = 1; i < tris.length; i++) {
            int256 key = sizes[i];
            uint256 j = i - 1;
            while (j > 0 && key < sizes[j]) {
                sizes[j + 1] = sizes[j];
                idxs[j + 1] = idxs[j];
                j--;
            }
            sizes[j + 1] = key;
            idxs[j + 1] = i;
        }

        uint256 nToCull = tris.length - nHighlights;
        assembly {
            mstore(idxs, sub(mload(idxs), nToCull))
        }

        return idxs;
    }
}

/**
Hold some functions externally to reduce contract size for mainnet deployment
 */
library GeomUtils {
    /// misc constants
    int256 constant MIN_INT = type(int256).min;
    int256 constant MAX_INT = type(int256).max;

    /// constants for doing trig
    int256 constant PI = 3141592653589793238; // pi as an 18 decimal value (wad)

    /// parameters that control geometry creation
    struct GeomSpec {
        string name;
        int256 id;
        int256 forceInitialSize;
        uint256 maxPrisms;
        int256 minTriRad;
        int256 maxTriRad;
        bool varySize;
        int256 depthMultiplier;
        bool isSymmetricX;
        bool isSymmetricY;
        int256 probVertOpp;
        int256 probAdjRec;
        int256 probVertOppRec;
    }

    /// variables uses when creating the initial 2d triangles
    struct TriVars {
        uint256 nextTriIdx;
        int256[3][3][] tris;
        int256[3][3] tri;
        int256 zBackRef;
        int256 zFrontRef;
        int256[] zFronts;
        int256[] zBacks;
        bool recursiveAttempt;
    }

    /// variables used when creating 3d prisms
    struct GeomVars {
        int256 rotX;
        int256 rotY;
        int256 rotZ;
        int256[3][2] extents;
        int256[3] center;
        int256 width;
        int256 height;
        int256 extent;
        int256 scaleNum;
        uint256[] hltPrismIdx;
        int256[3][3][] trisBack;
        int256[3][3][] trisFront;
        uint256 nPrisms;
    }

    /** @dev generate parameters that will control how the geometry is built */
    function generateSpec(bytes32 tokenHash)
        external
        view
        returns (GeomSpec memory spec)
    {
        //  'randomly' select 1 of possible geometry specifications
        uint256 specId = getSpecId(
            tokenHash,
            [
                [int256(0), 1000],
                [int256(1000), 3000],
                [int256(3000), 3500],
                [int256(3500), 4500],
                [int256(4500), 5000],
                [int256(5000), 6000],
                [int256(6000), 8000]
            ]
        );

        bool isSymmetricX = GeomUtils.randN(tokenHash, "symmX", 0, 2) > 0;
        bool isSymmetricY = GeomUtils.randN(tokenHash, "symmY", 0, 2) > 0;

        int256 defaultDepthMultiplier = randN(tokenHash, "depthMult", 80, 120);
        int256 defaultMinTriRad = 4800;
        int256 defaultMaxTriRad = defaultMinTriRad * 3;
        uint256 defaultMaxPrisms = uint256(
            randN(tokenHash, "maxPrisms", 8, 16)
        );

        if (specId == 0) {
            /// all vertically opposite
            spec = GeomSpec({
                id: 0,
                name: "Verticalized",
                forceInitialSize: (defaultMinTriRad * 5) / 2,
                maxPrisms: defaultMaxPrisms,
                minTriRad: defaultMinTriRad,
                maxTriRad: defaultMaxTriRad,
                varySize: true,
                depthMultiplier: defaultDepthMultiplier,
                probVertOpp: 100,
                probVertOppRec: 100,
                probAdjRec: 0,
                isSymmetricX: isSymmetricX,
                isSymmetricY: isSymmetricY
            });
        } else if (specId == 1) {
            /// fully adjacent
            spec = GeomSpec({
                id: 1,
                name: "Adjoint",
                forceInitialSize: (defaultMinTriRad * 5) / 2,
                maxPrisms: defaultMaxPrisms,
                minTriRad: defaultMinTriRad,
                maxTriRad: defaultMaxTriRad,
                varySize: true,
                depthMultiplier: defaultDepthMultiplier,
                probVertOpp: 0,
                probVertOppRec: 0,
                probAdjRec: 100,
                isSymmetricX: isSymmetricX,
                isSymmetricY: isSymmetricY
            });
        } else if (specId == 2) {
            /// few but big
            spec = GeomSpec({
                id: 2,
                name: "Cetacean",
                forceInitialSize: 0,
                maxPrisms: 8,
                minTriRad: defaultMinTriRad * 3,
                maxTriRad: defaultMinTriRad * 4,
                varySize: true,
                depthMultiplier: defaultDepthMultiplier,
                probVertOpp: 50,
                probVertOppRec: 50,
                probAdjRec: 50,
                isSymmetricX: isSymmetricX,
                isSymmetricY: isSymmetricY
            });
        } else if (specId == 3) {
            /// lots but small
            spec = GeomSpec({
                id: 3,
                name: "Swarm",
                forceInitialSize: 0,
                maxPrisms: 16,
                minTriRad: defaultMinTriRad,
                maxTriRad: defaultMinTriRad * 2,
                varySize: true,
                depthMultiplier: defaultDepthMultiplier,
                probVertOpp: 50,
                probVertOppRec: 0,
                probAdjRec: 0,
                isSymmetricX: isSymmetricX,
                isSymmetricY: isSymmetricY
            });
        } else if (specId == 4) {
            /// all same size
            spec = GeomSpec({
                id: 4,
                name: "Isomorphic",
                forceInitialSize: 0,
                maxPrisms: defaultMaxPrisms,
                minTriRad: defaultMinTriRad,
                maxTriRad: defaultMaxTriRad,
                varySize: false,
                depthMultiplier: defaultDepthMultiplier,
                probVertOpp: 50,
                probVertOppRec: 50,
                probAdjRec: 50,
                isSymmetricX: isSymmetricX,
                isSymmetricY: isSymmetricY
            });
        } else if (specId == 5) {
            /// trains
            spec = GeomSpec({
                id: 5,
                name: "Extruded",
                forceInitialSize: 0,
                maxPrisms: 10,
                minTriRad: defaultMinTriRad,
                maxTriRad: defaultMaxTriRad,
                varySize: true,
                depthMultiplier: defaultDepthMultiplier,
                probVertOpp: 50,
                probVertOppRec: 50,
                probAdjRec: 50,
                isSymmetricX: isSymmetricX,
                isSymmetricY: isSymmetricY
            });
        } else if (specId == 6) {
            /// flatpack
            spec = GeomSpec({
                id: 6,
                name: "Uniform",
                forceInitialSize: 0,
                maxPrisms: 12,
                minTriRad: defaultMinTriRad,
                maxTriRad: defaultMaxTriRad,
                varySize: true,
                depthMultiplier: defaultDepthMultiplier,
                probVertOpp: 50,
                probVertOppRec: 50,
                probAdjRec: 50,
                isSymmetricX: isSymmetricX,
                isSymmetricY: isSymmetricY
            });
        } else {
            revert("invalid specId");
        }
    }

    /** @dev make triangles to the side of a reference triangle */
    function makeAdjacentTriangles(
        bytes32 tokenHash,
        uint256 attemptNum,
        uint256 refIdx,
        TriVars memory triVars,
        GeomSpec memory geomSpec,
        int256 overrideSideIdx,
        int256 overrideScale,
        int256 depth
    ) public view returns (TriVars memory) {
        /// get the side index (0, 1 or 2)
        int256 sideIdx;
        if (overrideSideIdx == -1) {
            sideIdx = randN(
                tokenHash,
                string(abi.encodePacked("sideIdx", attemptNum, depth)),
                0,
                2
            );
        } else {
            sideIdx = overrideSideIdx;
        }

        /// get the scale
        /// this value is scaled up by 1e3 (desired range is 0.333 to 0.8)
        /// the scale will be divided out when used
        int256 scale;
        if (geomSpec.varySize) {
            if (overrideScale == -1) {
                scale = randN(
                    tokenHash,
                    string(abi.encodePacked("scaleAdj", attemptNum, depth)),
                    333,
                    800
                );
            } else {
                scale = overrideScale;
            }
        } else {
            scale = 1e3;
        }

        /// make a new triangle
        int256[3][3] memory newTri = makeTriAdjacent(
            tokenHash,
            geomSpec,
            attemptNum,
            triVars.tris[refIdx],
            sideIdx,
            scale,
            depth
        );

        /// set the zbackref and frontbackref
        triVars.zBackRef = -1; /// calculate a new z back
        triVars.zFrontRef = -1; /// calculate a new z ftont

        // try to add the triangle, and use the reference z height
        triVars.recursiveAttempt = false;
        bool wasAdded = attemptToAddTri(newTri, tokenHash, triVars, geomSpec);

        if (wasAdded) {
            // run again
            if (
                randN(
                    tokenHash,
                    string(
                        abi.encodePacked("addAdjRecursive", attemptNum, depth)
                    ),
                    0,
                    100
                ) <= geomSpec.probAdjRec
            ) {
                triVars = makeAdjacentTriangles(
                    tokenHash,
                    attemptNum,
                    triVars.nextTriIdx - 1,
                    triVars,
                    geomSpec,
                    sideIdx,
                    666, /// always make the next one 2/3 scale
                    depth + 1
                );
            }
        }
        return triVars;
    }

    /** @dev make triangles vertically opposite a reference triangle */
    function makeVerticallyOppositeTriangles(
        bytes32 tokenHash,
        uint256 attemptNum,
        uint256 refIdx,
        TriVars memory triVars,
        GeomSpec memory geomSpec,
        int256 overrideSideIdx,
        int256 overrideScale,
        int256 depth
    ) public view returns (TriVars memory) {
        /// get the side index (0, 1 or 2)
        int256 sideIdx;
        if (overrideSideIdx == -1) {
            sideIdx = randN(
                tokenHash,
                string(abi.encodePacked("vertOppSideIdx", attemptNum, depth)),
                0,
                2
            );
        } else {
            sideIdx = overrideSideIdx;
        }

        /// get the scale
        /// this value is scaled up by 1e3
        /// use attemptNum in seedModifier to ensure unique values each attempt
        int256 scale;
        if (geomSpec.varySize) {
            if (overrideScale == -1) {
                if (
                    // prettier-ignore
                    randN(
                        tokenHash,
                        string(abi.encodePacked("vertOppScale1", attemptNum, depth)),
                        0,
                        100
                    ) > 33
                ) {
                    // prettier-ignore
                    if (
                        randN(
                            tokenHash,
                            string(abi.encodePacked("vertOppScale2", attemptNum, depth)  ),
                            0,
                            100
                        ) > 50
                    ) {
                        scale = 1000; /// desired = 1 (same scale)
                    } else {
                        scale = 500; /// desired = 0.5 (half scale)
                    }
                } else {
                    scale = 2000; /// desired = 2 (double scale)
                }
            } else {
                scale = overrideScale;
            }
        } else {
            scale = 1e3;
        }

        /// make a new triangle
        int256[3][3] memory newTri = makeTriVertOpp(
            triVars.tris[refIdx],
            geomSpec,
            sideIdx,
            scale
        );

        /// set the zbackref and frontbackref
        triVars.zBackRef = -1; /// calculate a new z back
        triVars.zFrontRef = triVars.zFronts[refIdx];

        // try to add the triangle, and use the reference z height
        triVars.recursiveAttempt = false;
        bool wasAdded = attemptToAddTri(newTri, tokenHash, triVars, geomSpec);

        if (wasAdded) {
            /// run again
            if (
                randN(
                    tokenHash,
                    string(
                        abi.encodePacked("recursiveVertOpp", attemptNum, depth)
                    ),
                    0,
                    100
                ) <= geomSpec.probVertOppRec
            ) {
                triVars = makeVerticallyOppositeTriangles(
                    tokenHash,
                    attemptNum,
                    refIdx,
                    triVars,
                    geomSpec,
                    sideIdx,
                    666, /// always make the next one 2/3 scale
                    depth + 1
                );
            }
        }

        return triVars;
    }

    /** @dev place a triangle vertically opposite over the given point 
    @param refTri the reference triangle to base the new triangle on
    */
    function makeTriVertOpp(
        int256[3][3] memory refTri,
        GeomSpec memory geomSpec,
        int256 sideIdx,
        int256 scale
    ) internal view returns (int256[3][3] memory) {
        /// calculate the center of the reference triangle
        /// add and then divide by 1e3 (the factor by which scale is scaled up)
        int256 centerDist = (getRadiusLen(refTri) * (1e3 + scale)) / 1e3;

        /// get the new triangle's direction
        int256 newAngle = sideIdx *
            120 +
            60 +
            (isTriPointingUp(refTri) ? int256(60) : int256(0));

        int256 spacing = 64;

        /// calculate the true offset
        int256[3] memory offset = vector3RotateZ(
            [int256(0), centerDist + spacing, 0],
            newAngle
        );

        int256[3] memory centerVec = getCenterVec(refTri);
        int256[3] memory newCentre = ShackledMath.vector3Add(centerVec, offset);
        /// return the new triangle (div by 1e3 to account for scale)
        int256 newRadius = (scale * getRadiusLen(refTri)) / 1e3;
        newRadius = ShackledMath.min(geomSpec.maxTriRad, newRadius);
        newAngle -= 210;
        return makeTri(newCentre, newRadius, newAngle);
    }

    /** @dev make a new adjacent triangle
     */
    function makeTriAdjacent(
        bytes32 tokenHash,
        GeomSpec memory geomSpec,
        uint256 attemptNum,
        int256[3][3] memory refTri,
        int256 sideIdx,
        int256 scale,
        int256 depth
    ) internal view returns (int256[3][3] memory) {
        /// calculate the center of the new triangle
        /// add and then divide by 1e3 (the factor by which scale is scaled up)

        int256 centerDist = (getPerpLen(refTri) * (1e3 + scale)) / 1e3;

        /// get the new triangle's direction
        int256 newAngle = sideIdx *
            120 +
            (isTriPointingUp(refTri) ? int256(60) : int256(0));

        /// determine the direction of the offset offset
        /// get a unique random seed each attempt to ensure variation

        // prettier-ignore
        int256 offsetDirection = randN(
            tokenHash,
            string(abi.encodePacked("lateralOffset", attemptNum, depth)),
            0, 
            1
        ) 
        * 2 - 1;

        /// put if off to one side of the triangle if it's smaller
        /// scale is on order of 1e3
        int256 lateralOffset = (offsetDirection *
            (1e3 - scale) *
            getSideLen(refTri)) / 1e3;

        /// make a gap between the triangles
        int256 spacing = 6000;

        /// calculate the true offset
        int256[3] memory offset = vector3RotateZ(
            [lateralOffset, centerDist + spacing, 0],
            newAngle
        );

        int256[3] memory newCentre = ShackledMath.vector3Add(
            getCenterVec(refTri),
            offset
        );

        /// return the new triangle (div by 1e3 to account for scale)
        int256 newRadius = (scale * getRadiusLen(refTri)) / 1e3;
        newRadius = ShackledMath.min(geomSpec.maxTriRad, newRadius);
        newAngle -= 30;
        return makeTri(newCentre, newRadius, newAngle);
    }

    /** @dev  
    create a triangle centered at centre, 
    with length from centre to point of radius
    */
    function makeTri(
        int256[3] memory centre,
        int256 radius,
        int256 angle
    ) internal view returns (int256[3][3] memory tri) {
        /// create a vector to rotate around 3 times
        int256[3] memory offset = [radius, 0, 0];

        /// make 3 points of the tri
        for (uint256 i = 0; i < 3; i++) {
            int256 armAngle = 120 * int256(i);
            int256[3] memory offsetVec = vector3RotateZ(
                offset,
                armAngle + angle
            );

            tri[i] = ShackledMath.vector3Add(centre, offsetVec);
        }
    }

    /** @dev rotate a vector around x */
    function vector3RotateX(int256[3] memory v, int256 deg)
        internal
        view
        returns (int256[3] memory)
    {
        /// get the cos and sin of the angle
        (int256 cos, int256 sin) = trigHelper(deg);

        /// calculate new y and z (scaling down to account for trig scaling)
        int256 y = ((v[1] * cos) - (v[2] * sin)) / 1e18;
        int256 z = ((v[1] * sin) + (v[2] * cos)) / 1e18;
        return [v[0], y, z];
    }

    /** @dev rotate a vector around y */
    function vector3RotateY(int256[3] memory v, int256 deg)
        internal
        view
        returns (int256[3] memory)
    {
        /// get the cos and sin of the angle
        (int256 cos, int256 sin) = trigHelper(deg);

        /// calculate new x and z (scaling down to account for trig scaling)
        int256 x = ((v[0] * cos) - (v[2] * sin)) / 1e18;
        int256 z = ((v[0] * sin) + (v[2] * cos)) / 1e18;
        return [x, v[1], z];
    }

    /** @dev rotate a vector around z */
    function vector3RotateZ(int256[3] memory v, int256 deg)
        internal
        view
        returns (int256[3] memory)
    {
        /// get the cos and sin of the angle
        (int256 cos, int256 sin) = trigHelper(deg);

        /// calculate new x and y (scaling down to account for trig scaling)
        int256 x = ((v[0] * cos) - (v[1] * sin)) / 1e18;
        int256 y = ((v[0] * sin) + (v[1] * cos)) / 1e18;
        return [x, y, v[2]];
    }

    /** @dev calculate sin and cos of an angle */
    function trigHelper(int256 deg)
        internal
        view
        returns (int256 cos, int256 sin)
    {
        /// deal with negative degrees here, since Trigonometry.sol can't
        int256 n360 = (ShackledMath.abs(deg) / 360) + 1;
        deg = (deg + (360 * n360)) % 360;
        uint256 rads = uint256((deg * PI) / 180);
        /// calculate radians (in 1e18 space)
        cos = Trigonometry.cos(rads);
        sin = Trigonometry.sin(rads);
    }

    /** @dev Get the 3d vector at the center of a triangle */
    function getCenterVec(int256[3][3] memory tri)
        internal
        view
        returns (int256[3] memory)
    {
        return
            ShackledMath.vector3DivScalar(
                ShackledMath.vector3Add(
                    ShackledMath.vector3Add(tri[0], tri[1]),
                    tri[2]
                ),
                3
            );
    }

    /** @dev Get the length from the center of a triangle to point*/
    function getRadiusLen(int256[3][3] memory tri)
        internal
        view
        returns (int256)
    {
        return
            ShackledMath.vector3Len(
                ShackledMath.vector3Sub(getCenterVec(tri), tri[0])
            );
    }

    /** @dev Get the length from any point on triangle to other point (equilateral)*/
    function getSideLen(int256[3][3] memory tri)
        internal
        view
        returns (int256)
    {
        // len * 0.886
        return (getRadiusLen(tri) * 8660) / 10000;
    }

    /** @dev Get the shortes length from center of triangle to side */
    function getPerpLen(int256[3][3] memory tri)
        internal
        view
        returns (int256)
    {
        return getRadiusLen(tri) / 2;
    }

    /** @dev Determine if a triangle is pointing up*/
    function isTriPointingUp(int256[3][3] memory tri)
        internal
        view
        returns (bool)
    {
        int256 centerY = getCenterVec(tri)[1];
        /// count how many verts are above this y value
        int256 nAbove = 0;
        for (uint256 i = 0; i < 3; i++) {
            if (tri[i][1] > centerY) {
                nAbove++;
            }
        }
        return nAbove == 1;
    }

    /** @dev check if two triangles are close */
    function areTrisClose(int256[3][3] memory tri1, int256[3][3] memory tri2)
        internal
        view
        returns (bool)
    {
        int256 lenBetweenCenters = ShackledMath.vector3Len(
            ShackledMath.vector3Sub(getCenterVec(tri1), getCenterVec(tri2))
        );
        return lenBetweenCenters < (getPerpLen(tri1) + getPerpLen(tri2));
    }

    /** @dev check if two triangles have overlapping points*/
    function areTrisPointsOverlapping(
        int256[3][3] memory tri1,
        int256[3][3] memory tri2
    ) internal view returns (bool) {
        /// check triangle a against b
        if (
            isPointInTri(tri1, tri2[0]) ||
            isPointInTri(tri1, tri2[1]) ||
            isPointInTri(tri1, tri2[2])
        ) {
            return true;
        }

        /// check triangle b against a
        if (
            isPointInTri(tri2, tri1[0]) ||
            isPointInTri(tri2, tri1[1]) ||
            isPointInTri(tri2, tri1[2])
        ) {
            return true;
        }

        /// otherwise they mustn't be overlapping
        return false;
    }

    /** @dev calculate if a point is in a tri*/
    function isPointInTri(int256[3][3] memory tri, int256[3] memory p)
        internal
        view
        returns (bool)
    {
        int256[3] memory p1 = tri[0];
        int256[3] memory p2 = tri[1];
        int256[3] memory p3 = tri[2];
        int256 alphaNum = (p2[1] - p3[1]) *
            (p[0] - p3[0]) +
            (p3[0] - p2[0]) *
            (p[1] - p3[1]);

        int256 alphaDenom = (p2[1] - p3[1]) *
            (p1[0] - p3[0]) +
            (p3[0] - p2[0]) *
            (p1[1] - p3[1]);

        int256 betaNum = (p3[1] - p1[1]) *
            (p[0] - p3[0]) +
            (p1[0] - p3[0]) *
            (p[1] - p3[1]);

        int256 betaDenom = (p2[1] - p3[1]) *
            (p1[0] - p3[0]) +
            (p3[0] - p2[0]) *
            (p1[1] - p3[1]);

        if (alphaDenom == 0 || betaDenom == 0) {
            return false;
        } else {
            int256 alpha = (alphaNum * 1e6) / alphaDenom;
            int256 beta = (betaNum * 1e6) / betaDenom;

            int256 gamma = 1e6 - alpha - beta;
            return alpha > 0 && beta > 0 && gamma > 0;
        }
    }

    /** @dev check all points of the tri to see if it overlaps with any other tris
     */
    function isTriOverlappingWithTris(
        int256[3][3] memory tri,
        int256[3][3][] memory tris,
        uint256 nextTriIdx
    ) internal view returns (bool) {
        /// check against all other tris added thus fat
        for (uint256 i = 0; i < nextTriIdx; i++) {
            if (
                areTrisClose(tri, tris[i]) ||
                areTrisPointsOverlapping(tri, tris[i])
            ) {
                return true;
            }
        }
        return false;
    }

    function isPointCloseToLine(
        int256[3] memory p,
        int256[3] memory l1,
        int256[3] memory l2
    ) internal view returns (bool) {
        int256 x0 = p[0];
        int256 y0 = p[1];
        int256 x1 = l1[0];
        int256 y1 = l1[1];
        int256 x2 = l2[0];
        int256 y2 = l2[1];
        int256 distanceNum = ShackledMath.abs(
            (x2 - x1) * (y1 - y0) - (x1 - x0) * (y2 - y1)
        );
        int256 distanceDenom = ShackledMath.hypot((x2 - x1), (y2 - y1));
        int256 distance = distanceNum / distanceDenom;
        if (distance < 8) {
            return true;
        }
    }

    /** compare a triangles points against the lines of other tris */
    function isTrisPointsCloseToLines(
        int256[3][3] memory tri,
        int256[3][3][] memory tris,
        uint256 nextTriIdx
    ) internal view returns (bool) {
        for (uint256 i = 0; i < nextTriIdx; i++) {
            for (uint256 p = 0; p < 3; p++) {
                if (isPointCloseToLine(tri[p], tris[i][0], tris[i][1])) {
                    return true;
                }
                if (isPointCloseToLine(tri[p], tris[i][1], tris[i][2])) {
                    return true;
                }
                if (isPointCloseToLine(tri[p], tris[i][2], tris[i][0])) {
                    return true;
                }
            }
        }
    }

    /** @dev check if tri to add meets certain criteria */
    function isTriLegal(
        int256[3][3] memory tri,
        int256[3][3][] memory tris,
        uint256 nextTriIdx,
        int256 minTriRad
    ) internal view returns (bool) {
        // check radius first as point checks will fail
        // if the radius is too small
        if (getRadiusLen(tri) < minTriRad) {
            return false;
        }
        return (!isTriOverlappingWithTris(tri, tris, nextTriIdx) &&
            !isTrisPointsCloseToLines(tri, tris, nextTriIdx));
    }

    /** @dev helper function to add triangles */
    function attemptToAddTri(
        int256[3][3] memory tri,
        bytes32 tokenHash,
        TriVars memory triVars,
        GeomSpec memory geomSpec
    ) internal view returns (bool added) {
        bool isLegal = isTriLegal(
            tri,
            triVars.tris,
            triVars.nextTriIdx,
            geomSpec.minTriRad
        );
        if (isLegal && triVars.nextTriIdx < geomSpec.maxPrisms) {
            // add the triangle
            triVars.tris[triVars.nextTriIdx] = tri;
            added = true;

            // add the new zs
            if (triVars.zBackRef == -1) {
                /// z back ref is not provided, calculate it
                triVars.zBacks[triVars.nextTriIdx] = calculateZ(
                    tri,
                    tokenHash,
                    triVars.nextTriIdx,
                    geomSpec,
                    false
                );
            } else {
                /// use the provided z back (from the ref)
                triVars.zBacks[triVars.nextTriIdx] = triVars.zBackRef;
            }
            if (triVars.zFrontRef == -1) {
                /// z front ref is not provided, calculate it
                triVars.zFronts[triVars.nextTriIdx] = calculateZ(
                    tri,
                    tokenHash,
                    triVars.nextTriIdx,
                    geomSpec,
                    true
                );
            } else {
                /// use the provided z front (from the ref)
                triVars.zFronts[triVars.nextTriIdx] = triVars.zFrontRef;
            }

            // increment the tris counter
            triVars.nextTriIdx += 1;

            // if we're using any type of symmetry then attempt to add a symmetric triangle
            // only do this recursively once
            if (
                (geomSpec.isSymmetricX || geomSpec.isSymmetricY) &&
                (!triVars.recursiveAttempt)
            ) {
                int256[3][3] memory symTri = copyTri(tri);

                if (geomSpec.isSymmetricX) {
                    symTri[0][0] = -symTri[0][0];
                    symTri[1][0] = -symTri[1][0];
                    symTri[2][0] = -symTri[2][0];
                    // symCenter[0] = -symCenter[0];
                }

                if (geomSpec.isSymmetricY) {
                    symTri[0][1] = -symTri[0][1];
                    symTri[1][1] = -symTri[1][1];
                    symTri[2][1] = -symTri[2][1];
                    // symCenter[1] = -symCenter[1];
                }

                if (
                    (geomSpec.isSymmetricX || geomSpec.isSymmetricY) &&
                    !(geomSpec.isSymmetricX && geomSpec.isSymmetricY)
                ) {
                    symTri = [symTri[2], symTri[1], symTri[0]];
                }

                triVars.recursiveAttempt = true;
                triVars.zBackRef = triVars.zBacks[triVars.nextTriIdx - 1];
                triVars.zFrontRef = triVars.zFronts[triVars.nextTriIdx - 1];
                attemptToAddTri(symTri, tokenHash, triVars, geomSpec);
            }
        }
    }

    /** @dev rotate a triangle by x, y, or z 
    @param axis 0 = x, 1 = y, 2 = z
    */
    function triRotHelp(
        int256 axis,
        int256[3][3] memory tri,
        int256 rot
    ) internal view returns (int256[3][3] memory) {
        if (axis == 0) {
            return [
                vector3RotateX(tri[0], rot),
                vector3RotateX(tri[1], rot),
                vector3RotateX(tri[2], rot)
            ];
        } else if (axis == 1) {
            return [
                vector3RotateY(tri[0], rot),
                vector3RotateY(tri[1], rot),
                vector3RotateY(tri[2], rot)
            ];
        } else if (axis == 2) {
            return [
                vector3RotateZ(tri[0], rot),
                vector3RotateZ(tri[1], rot),
                vector3RotateZ(tri[2], rot)
            ];
        }
    }

    /** @dev a helper to run rotation functions on back/front triangles */
    function triBfHelp(
        int256 axis,
        int256[3][3][] memory trisBack,
        int256[3][3][] memory trisFront,
        int256 rot
    ) internal view returns (int256[3][3][] memory, int256[3][3][] memory) {
        int256[3][3][] memory trisBackNew = new int256[3][3][](trisBack.length);
        int256[3][3][] memory trisFrontNew = new int256[3][3][](
            trisFront.length
        );

        for (uint256 i = 0; i < trisBack.length; i++) {
            trisBackNew[i] = triRotHelp(axis, trisBack[i], rot);
            trisFrontNew[i] = triRotHelp(axis, trisFront[i], rot);
        }

        return (trisBackNew, trisFrontNew);
    }

    /** @dev get the maximum extent of the geometry (vertical or horizontal) */
    function getExtents(int256[3][3][] memory tris)
        internal
        view
        returns (int256[3][2] memory)
    {
        int256 minX = MAX_INT;
        int256 maxX = MIN_INT;
        int256 minY = MAX_INT;
        int256 maxY = MIN_INT;
        int256 minZ = MAX_INT;
        int256 maxZ = MIN_INT;

        for (uint256 i = 0; i < tris.length; i++) {
            for (uint256 j = 0; j < tris[i].length; j++) {
                minX = ShackledMath.min(minX, tris[i][j][0]);
                maxX = ShackledMath.max(maxX, tris[i][j][0]);
                minY = ShackledMath.min(minY, tris[i][j][1]);
                maxY = ShackledMath.max(maxY, tris[i][j][1]);
                minZ = ShackledMath.min(minZ, tris[i][j][2]);
                maxZ = ShackledMath.max(maxZ, tris[i][j][2]);
            }
        }
        return [[minX, minY, minZ], [maxX, maxY, maxZ]];
    }

    /** @dev go through each triangle and apply a 'height' */
    function calculateZ(
        int256[3][3] memory tri,
        bytes32 tokenHash,
        uint256 nextTriIdx,
        GeomSpec memory geomSpec,
        bool front
    ) internal view returns (int256) {
        int256 h;
        string memory seedMod = string(abi.encodePacked("calcZ", nextTriIdx));
        if (front) {
            if (geomSpec.id == 6) {
                h = 1;
            } else {
                if (randN(tokenHash, seedMod, 0, 10) > 9) {
                    if (randN(tokenHash, seedMod, 0, 10) > 3) {
                        h = 10;
                    } else {
                        h = 22;
                    }
                } else {
                    if (randN(tokenHash, seedMod, 0, 10) > 5) {
                        h = 8;
                    } else {
                        h = 1;
                    }
                }
            }
        } else {
            if (geomSpec.id == 6) {
                h = -1;
            } else {
                if (geomSpec.id == 5) {
                    h = -randN(tokenHash, seedMod, 2, 20);
                } else {
                    h = -2;
                }
            }
        }
        if (geomSpec.id == 5) {
            h += 10;
        }
        return h * geomSpec.depthMultiplier;
    }

    /** @dev roll a specId given a list of weightings */
    function getSpecId(bytes32 tokenHash, int256[2][7] memory weightings)
        internal
        view
        returns (uint256)
    {
        int256 n = GeomUtils.randN(
            tokenHash,
            "specId",
            weightings[0][0],
            weightings[weightings.length - 1][1]
        );
        for (uint256 i = 0; i < weightings.length; i++) {
            if (weightings[i][0] <= n && n <= weightings[i][1]) {
                return i;
            }
        }
    }

    /** @dev get a random number between two numbers
    with a uniform probability distribution
    @param randomSeed a hash that we can use to 'randomly' get a number 
    @param seedModifier some string to make the result unique for this tokenHash
    @param min the minimum number (inclusive)
    @param max the maximum number (inclusive)

    examples:
        to get binary output (0 or 1), set min as 0 and max as 1
        
     */
    function randN(
        bytes32 randomSeed,
        string memory seedModifier,
        int256 min,
        int256 max
    ) internal view returns (int256) {
        /// use max() to ensure modulo != 0
        return
            int256(
                uint256(keccak256(abi.encodePacked(randomSeed, seedModifier))) %
                    uint256(ShackledMath.max(1, (max + 1 - min)))
            ) + min;
    }

    /** @dev clip an array of tris to a certain length (to trim empty tail slots) */
    function clipTrisToLength(int256[3][3][] memory arr, uint256 desiredLen)
        internal
        view
        returns (int256[3][3][] memory)
    {
        uint256 n = arr.length - desiredLen;
        assembly {
            mstore(arr, sub(mload(arr), n))
        }
        return arr;
    }

    /** @dev clip an array of Z values to a certain length (to trim empty tail slots) */
    function clipZsToLength(int256[] memory arr, uint256 desiredLen)
        internal
        view
        returns (int256[] memory)
    {
        uint256 n = arr.length - desiredLen;
        assembly {
            mstore(arr, sub(mload(arr), n))
        }
        return arr;
    }

    /** @dev make a copy of a triangle */
    function copyTri(int256[3][3] memory tri)
        internal
        view
        returns (int256[3][3] memory)
    {
        return [
            [tri[0][0], tri[0][1], tri[0][2]],
            [tri[1][0], tri[1][1], tri[1][2]],
            [tri[2][0], tri[2][1], tri[2][2]]
        ];
    }

    /** @dev make a copy of an array of triangles */
    function copyTris(int256[3][3][] memory tris)
        internal
        view
        returns (int256[3][3][] memory)
    {
        int256[3][3][] memory newTris = new int256[3][3][](tris.length);
        for (uint256 i = 0; i < tris.length; i++) {
            newTris[i] = copyTri(tris[i]);
        }
        return newTris;
    }
}