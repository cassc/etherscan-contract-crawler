// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/ShackledRenderer.sol";

contract XShackledRenderer {
    constructor() {}

    function xrender(ShackledStructs.RenderParams calldata renderParams,int256 canvasDim,bool returnSVG) external view returns (string memory) {
        return ShackledRenderer.render(renderParams,canvasDim,returnSVG);
    }

    function xprepareGeometryForRender(ShackledStructs.RenderParams calldata renderParams,int256 canvasDim) external view returns (int256[12][3][] memory) {
        return ShackledRenderer.prepareGeometryForRender(renderParams,canvasDim);
    }
}