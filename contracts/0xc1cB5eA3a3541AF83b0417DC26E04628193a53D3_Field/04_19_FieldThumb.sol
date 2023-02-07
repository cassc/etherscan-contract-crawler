//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './SVG.sol';
import './Utils.sol';

function renderThumb(uint256 tokenId, uint8 appearance)
    pure
    returns (string memory)
{
    string memory spinners;
    for (uint8 y = 0; y < 3; y++) {
        for (uint8 x = 0; x < 3; x++) {
            spinners = string.concat(spinners, render(x, y, tokenId));
        }
    }
    string
        memory darkSnippet = '{--fill:white;background:linear-gradient(#2d2a2a,#2b2f71);}';
    return
        string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="300" viewBox="0 0 300 300" id="a',
            utils.uint2str(appearance),
            '">',
            spinners,
            '<style>line{stroke-linecap:round;stroke:var(--fill);stroke-width:2} #a1,#a0{--fill:black;background:linear-gradient(#b9b6d0,#ffffff);}@media(prefers-color-scheme:dark){#a0',
            darkSnippet,
            '}#a2',
            darkSnippet,
            '@keyframes s {0% {opacity:1;}100%{opacity:0;}}#a1{background:#eee !important;}#a2{background:#202124 !important;}</style>',
            '</svg>'
        );
}

function render(
    uint8 x,
    uint8 y,
    uint256 tokenId
) pure returns (string memory) {
    uint256 duration = 1000 - utils.randomUint8(x * 50 + y + tokenId * 100);
    return
        svg.el(
            'svg',
            string.concat(
                svg.prop('x', utils.uint2str(x * 70 + 60)),
                svg.prop('y', utils.uint2str(y * 70 + 60))
            ),
            parts(duration, tokenId, x, y)
        );
}

function parts(
    uint256 duration,
    uint256 tokenId,
    uint8 x,
    uint8 y
) pure returns (string memory) {
    uint256 seed = tokenId * 792 + x * 7 + y * 37;
    bool same = tokenId % 2 == 1;
    uint32 partsCount = same ? 12 : utils.randomUint8(seed) / 18 + 4;
    string memory result;
    uint8 x1 = same ? 2 : utils.randomUint8(seed) / 18 + 1;
    uint8 x2 = same ? 9 : utils.randomUint8(seed + 1000) / 16 + 2;
    for (uint8 index = 0; index < partsCount; index++) {
        result = string.concat(
            result,
            linePart(duration, index, partsCount, seed, same, x1, x2)
        );
    }
    return result;
}

function linePart(
    uint256 duration,
    uint32 index,
    uint32 partsCount,
    uint256 seed,
    bool same,
    uint8 x1,
    uint8 x2
) pure returns (string memory) {
    return
        svg.el(
            'line',
            string.concat(
                getLineParts(index, partsCount, x1, x2),
                svg.prop(
                    'style',
                    linePartStyle(
                        duration,
                        index,
                        partsCount,
                        getStrokeWidth(same, seed)
                    )
                )
            )
        );
}

function getLineParts(
    uint32 index,
    uint32 partsCount,
    uint8 x1,
    uint8 x2
) pure returns (string memory) {
    return
        string.concat(
            svg.prop('transform', linePartTransform(index, partsCount)),
            svg.prop('x1', utils.uint2str(x1)),
            svg.prop('y1', '20'),
            svg.prop('x2', utils.uint2str(x2)),
            svg.prop('y2', '20')
        );
}

function getStrokeWidth(bool same, uint256 seed) pure returns (string memory) {
    return
        same
            ? ''
            : string.concat(
                'stroke-width:',
                utils.uint2str(utils.randomUint8(seed + 99) / 128 + 1)
            );
}

function linePartTransform(uint32 index, uint32 partsCount)
    pure
    returns (string memory)
{
    uint256 stepDeg = 360 / partsCount;
    return string.concat('rotate(', utils.uint2str(index * stepDeg), ' 20 20)');
}

function linePartStyle(
    uint256 duration,
    uint32 index,
    uint32 partsCount,
    string memory strokeWidth
) pure returns (string memory) {
    uint256 stepDuration = duration / partsCount;
    uint256 delay = duration - index * stepDuration;
    return
        string.concat(
            'animation:',
            utils.uint2str(duration),
            'ms linear -',
            utils.uint2str(delay),
            'ms infinite normal none running s;',
            strokeWidth
        );
}