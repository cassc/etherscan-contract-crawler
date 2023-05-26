// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/ShackledGenesis.sol";

contract XShackledGenesis {
    constructor() {}

    function xgenerateGenesisPiece(bytes32 tokenHash) external view returns (ShackledStructs.RenderParams memory, ShackledStructs.Metadata memory) {
        return ShackledGenesis.generateGenesisPiece(tokenHash);
    }

    function xgenerateGeometryAndColors(bytes32 tokenHash,int256[3] calldata objPosition) external view returns (ShackledGenesis.FacesVertsCols memory, ColorUtils.ColScheme memory, GeomUtils.GeomSpec memory, GeomUtils.GeomVars memory) {
        return ShackledGenesis.generateGeometryAndColors(tokenHash,objPosition);
    }

    function xcreate2dTris(bytes32 tokenHash,GeomUtils.GeomSpec calldata geomSpec) external view returns (int256[3][3][] memory, int256[] memory, int256[] memory) {
        return ShackledGenesis.create2dTris(tokenHash,geomSpec);
    }

    function xprismify(bytes32 tokenHash,int256[3][3][] calldata tris,int256[] calldata zFronts,int256[] calldata zBacks) external view returns (GeomUtils.GeomVars memory) {
        return ShackledGenesis.prismify(tokenHash,tris,zFronts,zBacks);
    }

    function xmakeFacesVertsCols(bytes32 tokenHash,int256[3][3][] calldata tris,GeomUtils.GeomVars calldata geomVars,ColorUtils.ColScheme calldata scheme,int256[3] calldata objPosition) external view returns (ShackledGenesis.FacesVertsCols memory) {
        return ShackledGenesis.makeFacesVertsCols(tokenHash,tris,geomVars,scheme,objPosition);
    }
}

contract XColorUtils {
    constructor() {}

    function xgetColForPrism(bytes32 tokenHash,int256[3][3] calldata triFront,ColorUtils.SubScheme calldata subScheme,int256[3][2] calldata extents) external view returns (int256[3][6] memory) {
        return ColorUtils.getColForPrism(tokenHash,triFront,subScheme,extents);
    }

    function xgetSchemeId(bytes32 tokenHash,int256[2][10] calldata weightings) external view returns (uint256) {
        return ColorUtils.getSchemeId(tokenHash,weightings);
    }

    function xcopyColor(int256[3] calldata c) external view returns (int256[3] memory) {
        return ColorUtils.copyColor(c);
    }

    function xgetScheme(bytes32 tokenHash,int256[3][3][] calldata tris) external view returns (ColorUtils.ColScheme memory) {
        return ColorUtils.getScheme(tokenHash,tris);
    }

    function xhsv2rgb(int256 h,int256 s,int256 v) external view returns (int256[3] memory) {
        return ColorUtils.hsv2rgb(h,s,v);
    }

    function xrgb2hsv(int256 r,int256 g,int256 b) external view returns (int256[3] memory) {
        return ColorUtils.rgb2hsv(r,g,b);
    }

    function xgetJiggle(int256[3] calldata jiggle,bytes32 randomSeed,int256 seedModifier) external view returns (int256[3] memory) {
        return ColorUtils.getJiggle(jiggle,randomSeed,seedModifier);
    }

    function xinArray(uint256[] calldata array,uint256 value) external view returns (bool) {
        return ColorUtils.inArray(array,value);
    }

    function xapplyDirHelp(int256[3][3] calldata triFront,int256[3] calldata colA,int256[3] calldata colB,int256 dirCode,bool isInnerGradient,int256[3][2] calldata extents) external view returns (int256[3][3] memory) {
        return ColorUtils.applyDirHelp(triFront,colA,colB,dirCode,isInnerGradient,extents);
    }

    function xgetOrderedPointIdxsInDir(int256[3][3] calldata tri,int256 dirCode) external view returns (uint256[3] memory) {
        return ColorUtils.getOrderedPointIdxsInDir(tri,dirCode);
    }

    function xinterpColHelp(int256[3] calldata colA,int256[3] calldata colB,int256 low,int256 high,int256 val) external view returns (int256[3] memory) {
        return ColorUtils.interpColHelp(colA,colB,low,high,val);
    }

    function xgetHighlightPrismIdxs(int256[3][3][] calldata tris,bytes32 tokenHash,uint256 nHighlights,int256 varCode,int256 selCode) external view returns (uint256[] memory) {
        return ColorUtils.getHighlightPrismIdxs(tris,tokenHash,nHighlights,varCode,selCode);
    }

    function xgetSortedTrisIdxs(int256[3][3][] calldata tris,uint256 nHighlights,int256 varCode,int256 selCode) external view returns (uint256[] memory) {
        return ColorUtils.getSortedTrisIdxs(tris,nHighlights,varCode,selCode);
    }
}

contract XGeomUtils {
    constructor() {}

    function xgenerateSpec(bytes32 tokenHash) external view returns (GeomUtils.GeomSpec memory) {
        return GeomUtils.generateSpec(tokenHash);
    }

    function xmakeAdjacentTriangles(bytes32 tokenHash,uint256 attemptNum,uint256 refIdx,GeomUtils.TriVars calldata triVars,GeomUtils.GeomSpec calldata geomSpec,int256 overrideSideIdx,int256 overrideScale,int256 depth) external view returns (GeomUtils.TriVars memory) {
        return GeomUtils.makeAdjacentTriangles(tokenHash,attemptNum,refIdx,triVars,geomSpec,overrideSideIdx,overrideScale,depth);
    }

    function xmakeVerticallyOppositeTriangles(bytes32 tokenHash,uint256 attemptNum,uint256 refIdx,GeomUtils.TriVars calldata triVars,GeomUtils.GeomSpec calldata geomSpec,int256 overrideSideIdx,int256 overrideScale,int256 depth) external view returns (GeomUtils.TriVars memory) {
        return GeomUtils.makeVerticallyOppositeTriangles(tokenHash,attemptNum,refIdx,triVars,geomSpec,overrideSideIdx,overrideScale,depth);
    }

    function xmakeTriVertOpp(int256[3][3] calldata refTri,GeomUtils.GeomSpec calldata geomSpec,int256 sideIdx,int256 scale) external view returns (int256[3][3] memory) {
        return GeomUtils.makeTriVertOpp(refTri,geomSpec,sideIdx,scale);
    }

    function xmakeTriAdjacent(bytes32 tokenHash,GeomUtils.GeomSpec calldata geomSpec,uint256 attemptNum,int256[3][3] calldata refTri,int256 sideIdx,int256 scale,int256 depth) external view returns (int256[3][3] memory) {
        return GeomUtils.makeTriAdjacent(tokenHash,geomSpec,attemptNum,refTri,sideIdx,scale,depth);
    }

    function xmakeTri(int256[3] calldata centre,int256 radius,int256 angle) external view returns (int256[3][3] memory) {
        return GeomUtils.makeTri(centre,radius,angle);
    }

    function xvector3RotateX(int256[3] calldata v,int256 deg) external view returns (int256[3] memory) {
        return GeomUtils.vector3RotateX(v,deg);
    }

    function xvector3RotateY(int256[3] calldata v,int256 deg) external view returns (int256[3] memory) {
        return GeomUtils.vector3RotateY(v,deg);
    }

    function xvector3RotateZ(int256[3] calldata v,int256 deg) external view returns (int256[3] memory) {
        return GeomUtils.vector3RotateZ(v,deg);
    }

    function xtrigHelper(int256 deg) external view returns (int256, int256) {
        return GeomUtils.trigHelper(deg);
    }

    function xgetCenterVec(int256[3][3] calldata tri) external view returns (int256[3] memory) {
        return GeomUtils.getCenterVec(tri);
    }

    function xgetRadiusLen(int256[3][3] calldata tri) external view returns (int256) {
        return GeomUtils.getRadiusLen(tri);
    }

    function xgetSideLen(int256[3][3] calldata tri) external view returns (int256) {
        return GeomUtils.getSideLen(tri);
    }

    function xgetPerpLen(int256[3][3] calldata tri) external view returns (int256) {
        return GeomUtils.getPerpLen(tri);
    }

    function xisTriPointingUp(int256[3][3] calldata tri) external view returns (bool) {
        return GeomUtils.isTriPointingUp(tri);
    }

    function xareTrisClose(int256[3][3] calldata tri1,int256[3][3] calldata tri2) external view returns (bool) {
        return GeomUtils.areTrisClose(tri1,tri2);
    }

    function xareTrisPointsOverlapping(int256[3][3] calldata tri1,int256[3][3] calldata tri2) external view returns (bool) {
        return GeomUtils.areTrisPointsOverlapping(tri1,tri2);
    }

    function xisPointInTri(int256[3][3] calldata tri,int256[3] calldata p) external view returns (bool) {
        return GeomUtils.isPointInTri(tri,p);
    }

    function xisTriOverlappingWithTris(int256[3][3] calldata tri,int256[3][3][] calldata tris,uint256 nextTriIdx) external view returns (bool) {
        return GeomUtils.isTriOverlappingWithTris(tri,tris,nextTriIdx);
    }

    function xisPointCloseToLine(int256[3] calldata p,int256[3] calldata l1,int256[3] calldata l2) external view returns (bool) {
        return GeomUtils.isPointCloseToLine(p,l1,l2);
    }

    function xisTrisPointsCloseToLines(int256[3][3] calldata tri,int256[3][3][] calldata tris,uint256 nextTriIdx) external view returns (bool) {
        return GeomUtils.isTrisPointsCloseToLines(tri,tris,nextTriIdx);
    }

    function xisTriLegal(int256[3][3] calldata tri,int256[3][3][] calldata tris,uint256 nextTriIdx,int256 minTriRad) external view returns (bool) {
        return GeomUtils.isTriLegal(tri,tris,nextTriIdx,minTriRad);
    }

    function xattemptToAddTri(int256[3][3] calldata tri,bytes32 tokenHash,GeomUtils.TriVars calldata triVars,GeomUtils.GeomSpec calldata geomSpec) external view returns (bool) {
        return GeomUtils.attemptToAddTri(tri,tokenHash,triVars,geomSpec);
    }

    function xtriRotHelp(int256 axis,int256[3][3] calldata tri,int256 rot) external view returns (int256[3][3] memory) {
        return GeomUtils.triRotHelp(axis,tri,rot);
    }

    function xtriBfHelp(int256 axis,int256[3][3][] calldata trisBack,int256[3][3][] calldata trisFront,int256 rot) external view returns (int256[3][3][] memory, int256[3][3][] memory) {
        return GeomUtils.triBfHelp(axis,trisBack,trisFront,rot);
    }

    function xgetExtents(int256[3][3][] calldata tris) external view returns (int256[3][2] memory) {
        return GeomUtils.getExtents(tris);
    }

    function xcalculateZ(int256[3][3] calldata tri,bytes32 tokenHash,uint256 nextTriIdx,GeomUtils.GeomSpec calldata geomSpec,bool front) external view returns (int256) {
        return GeomUtils.calculateZ(tri,tokenHash,nextTriIdx,geomSpec,front);
    }

    function xgetSpecId(bytes32 tokenHash,int256[2][7] calldata weightings) external view returns (uint256) {
        return GeomUtils.getSpecId(tokenHash,weightings);
    }

    function xrandN(bytes32 randomSeed,string calldata seedModifier,int256 min,int256 max) external view returns (int256) {
        return GeomUtils.randN(randomSeed,seedModifier,min,max);
    }

    function xclipTrisToLength(int256[3][3][] calldata arr,uint256 desiredLen) external view returns (int256[3][3][] memory) {
        return GeomUtils.clipTrisToLength(arr,desiredLen);
    }

    function xclipZsToLength(int256[] calldata arr,uint256 desiredLen) external view returns (int256[] memory) {
        return GeomUtils.clipZsToLength(arr,desiredLen);
    }

    function xcopyTri(int256[3][3] calldata tri) external view returns (int256[3][3] memory) {
        return GeomUtils.copyTri(tri);
    }

    function xcopyTris(int256[3][3][] calldata tris) external view returns (int256[3][3][] memory) {
        return GeomUtils.copyTris(tris);
    }
}