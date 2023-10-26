//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

interface IMetavatarGenerator {
    struct MetavatarStruct {
        uint256 numShapes;
        string background;
        bool lightMode;
        string bgOpacity;
        bool animated;
    }

    struct Shape {
        uint256 shapeType; // 0: rectange, 1: ellipses, 2: triangle
        uint256 xpos;
        uint256 ypos;
        uint256 width;
        uint256 height;
        uint256 fillType; // 0: solid, 1: gradient
        string fillValue;
    }

    struct LG {
        string id;
        string stopColor1;
        string stopColor2;
        string stopOpacity1;
        string stopOpacity2;
    }

    function tokenURI(uint256 tokenId, string memory seed)
        external
        view
        returns (string memory);

    function dataURI(uint256 tokenId, string memory seed)
        external
        view
        returns (string memory);
}