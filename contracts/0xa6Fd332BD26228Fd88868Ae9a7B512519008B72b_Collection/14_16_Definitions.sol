//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import './svg.sol';
import './utils.sol';

contract Definitions {
    /*PUBLIC*/
    function defs(bytes memory hash) public pure returns (string memory) {
        return string.concat(
            masks(),
            clipPaths(),
            filters(hash)
        );
    }
    /*MASKS*/
   function masks() internal pure returns (string memory) {
        return string.concat(
            svg.el('mask', svg.prop('id','cutoutMask'), 
                string.concat(
                    svg.whiteRect(),
                    svg.rect(string.concat(svg.prop('x','118'), svg.prop('y', '55'), svg.prop('width', '64'), svg.prop('height', '108'), svg.prop('ry', '30'), svg.prop('rx', '30'))),
                    svg.rect(string.concat(svg.prop('x','118'), svg.prop('y', '110'), svg.prop('width', '64'), svg.prop('height', '140'), svg.prop('ry', '30'), svg.prop('rx', '30')))
                )
            ),
            svg.el('mask', svg.prop('id','topReflectionMask'), 
                string.concat(
                    svg.whiteRect(),
                    svg.rect(string.concat(svg.prop('x','122'), svg.prop('y', '55'), svg.prop('width', '56'), svg.prop('height', '190'), svg.prop('ry', '30'), svg.prop('rx', '30'), svg.prop('fill', 'black')))
                )
            )
        );
    }

    /*CLIP-PATHS*/
    function clipPaths() internal pure returns (string memory) {
        return string.concat(
            svg.el('clipPath', svg.prop('id', 'clipBottom'),
                svg.rect(string.concat(svg.prop('height', '150'), svg.prop('width', '300')))
            ),
            svg.el('clipPath', svg.prop('id', 'clipShadow'),
                string.concat(
                    svg.rect(string.concat(svg.prop('y', '220'), svg.prop('height', '300'), svg.prop('width', '300'))),
                    svg.rect(string.concat(svg.prop('y', '180'), svg.prop('height', '300'), svg.prop('width', '115'))),
                    svg.rect(string.concat(svg.prop('y', '180'), svg.prop('x', '185'), svg.prop('height', '300'), svg.prop('width', '115')))
                )
            )
        );
    }

    /*FILTERS*/
    function filters(bytes memory hash) internal pure returns (string memory) {
        return string.concat(
            sandFilter(hash),
            svg.filter(
                string.concat(svg.prop('id','dropShadowFilter'), svg.prop('height', '300'), svg.prop('width', '300'), svg.prop('y', '-25%'), svg.prop('x', '-50%')),
                string.concat(
                    svg.el('feGaussianBlur', string.concat(svg.prop('in', 'SourceAlpha'), svg.prop('stdDeviation', '6'))),
                    svg.el('feOffset', svg.prop('dy', '8')),
                    svg.el('feComposite', string.concat(svg.prop('operator', 'out'), svg.prop('in2', 'SourceAlpha')))
                )
            ),
            fineSandFilter(hash),
            svg.filter(
                string.concat(svg.prop('id','solidTextBGFilter')),
                string.concat(
                    svg.el('feFlood', string.concat(svg.prop('flood-color', 'white'), svg.prop('result', 'bg'))),
                    svg.el('feMerge', '', string.concat(
                            svg.el('feMergeNode', svg.prop('in', 'bg')),
                            svg.el('feMergeNode', svg.prop('in', 'SourceGraphic'))
                        )
                    )
                )
            )
        );
    }

    /*INTERNALS*/
    function sandFilter(bytes memory hash) internal pure returns (string memory) {
        uint256 seed = utils.getSandSeed(hash);
        uint256 scale = utils.getSandScale(hash);
        uint256 octaves = utils.getSandOctaves(hash);
        return svg.filter(
                string.concat(svg.prop('id','sandFilter'), svg.prop('height', '800%'), svg.prop('y', '-250%')),
                string.concat(
                    svg.el('feTurbulence', string.concat(svg.prop('baseFrequency', '0.01'), svg.prop('numOctaves', utils.uint2str(octaves)), svg.prop('seed', utils.uint2str(seed)), svg.prop('result', 'turbs'))),
                    svg.el('feDisplacementMap', string.concat(svg.prop('in2', 'turbs'), svg.prop('in', 'SourceGraphic'), svg.prop('scale', utils.uint2str(scale)), svg.prop('xChannelSelector', 'R'), svg.prop('yChannelSelector', 'G')))
                )
        );
    }

    function fineSandFilter(bytes memory hash) internal pure returns (string memory) {
        string memory redOffset;
        string memory greenOffset;
        string memory blueOffset;
        {
            redOffset = getColourOffset(hash, 0);
            greenOffset = getColourOffset(hash, 1);
            blueOffset = getColourOffset(hash, 2);
        }

        uint256 seed = utils.getFineSandSeed(hash);
        uint256 octaves = utils.getFineSandOctaves(hash);

        return svg.filter(
            svg.prop('id','fineSandFilter'),
            string.concat(
                fineSandfeTurbulence(seed, octaves),
                svg.el('feComponentTransfer', '', string.concat(
                    svg.el('feFuncR', string.concat(svg.prop('type', 'gamma'), svg.prop('offset', redOffset))),
                    svg.el('feFuncG', string.concat(svg.prop('type', 'gamma'), svg.prop('offset', greenOffset))),
                    svg.el('feFuncB', string.concat(svg.prop('type', 'gamma'), svg.prop('offset', blueOffset))),
                    svg.el('feFuncA', string.concat(svg.prop('type', 'linear'), svg.prop('intercept', '1')))
                ))
            )
        );
    }

    function fineSandfeTurbulence(uint256 seed, uint256 octaves) internal pure returns (string memory) {
        return svg.el('feTurbulence', string.concat(svg.prop('baseFrequency', '0.01'), svg.prop('numOctaves', utils.uint2str(octaves)), svg.prop('seed', utils.uint2str(seed)), svg.prop('result', 'turbs')));
    }

    function getColourOffset(bytes memory hash, uint256 offsetIndex) internal pure returns (string memory) {
        uint256 shift = utils.getColourOffsetShift(hash, offsetIndex); // 0 or 1. Positive or Negative
        uint256 change = utils.getColourOffsetChange(hash, offsetIndex); // 0 - 99 
        string memory sign = "";
        if(shift == 1) { sign = "-"; }
        return string(abi.encodePacked(
            sign, utils.generateDecimalString(change,1)
        ));
    }
}