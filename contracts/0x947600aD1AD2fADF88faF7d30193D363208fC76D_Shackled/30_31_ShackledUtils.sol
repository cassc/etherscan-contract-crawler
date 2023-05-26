// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/ShackledUtils.sol";

contract XShackledUtils {
    constructor() {}

    function xflattenTris(int256[3][3][] calldata tris) external pure returns (int256[3][] memory) {
        return ShackledUtils.flattenTris(tris);
    }

    function xunflattenVertsToTris(int256[3][] calldata verts) external pure returns (int256[3][3][] memory) {
        return ShackledUtils.unflattenVertsToTris(verts);
    }

    function xclipArray12ToLength(int256[12][] calldata arr,uint256 desiredLen) external pure returns (int256[12][] memory) {
        return ShackledUtils.clipArray12ToLength(arr,desiredLen);
    }

    function xuint2str(uint256 _i) external pure returns (string memory) {
        return ShackledUtils.uint2str(_i);
    }

    function xgetHex(uint256 _i) external pure returns (bytes memory) {
        return ShackledUtils.getHex(_i);
    }

    function xgetSVGContainer(string calldata encodedBitmap,int256 canvasDim,uint256 outputHeight,uint256 outputWidth) external view returns (string memory) {
        return ShackledUtils.getSVGContainer(encodedBitmap,canvasDim,outputHeight,outputWidth);
    }

    function xgetAttributes(ShackledStructs.Metadata calldata metadata) external pure returns (bytes memory) {
        return ShackledUtils.getAttributes(metadata);
    }

    function xgetEncodedMetadata(string calldata image,ShackledStructs.Metadata calldata metadata,uint256 tokenId) external view returns (string memory) {
        return ShackledUtils.getEncodedMetadata(image,metadata,tokenId);
    }

    function xgetEncodedBitmap(int256[12][] calldata fragments,int256[5][] calldata background,int256 canvasDim,bool invert) external view returns (string memory) {
        return ShackledUtils.getEncodedBitmap(fragments,background,canvasDim,invert);
    }

    function xwriteFragmentsToBytesArray(int256[12][] calldata fragments,bytes calldata bytesArray,uint256 canvasDimUnsigned,bool invert) external pure returns (bytes memory) {
        return ShackledUtils.writeFragmentsToBytesArray(fragments,bytesArray,canvasDimUnsigned,invert);
    }

    function xwriteBackgroundToBytesArray(int256[5][] calldata background,bytes calldata bytesArray,uint256 canvasDimUnsigned,bool invert) external pure returns (bytes memory) {
        return ShackledUtils.writeBackgroundToBytesArray(background,bytesArray,canvasDimUnsigned,invert);
    }
}

contract XBase64 {
    constructor() {}

    function xencode(bytes calldata data) external view returns (string memory) {
        return Base64.encode(data);
    }
}

contract XBytesUtils {
    constructor() {}

    function xchar(bytes1 b) external view returns (bytes1) {
        return BytesUtils.char(b);
    }

    function xbytes32string(bytes32 b32) external view returns (string memory) {
        return BytesUtils.bytes32string(b32);
    }

    function xhach(string calldata value) external view returns (string memory) {
        return BytesUtils.hach(value);
    }

    function xMergeBytes(bytes calldata a,bytes calldata b) external pure returns (bytes memory) {
        return BytesUtils.MergeBytes(a,b);
    }
}