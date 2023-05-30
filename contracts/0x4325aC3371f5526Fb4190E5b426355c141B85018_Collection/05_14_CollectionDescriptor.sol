// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import './SVG.sol';
import './Utils.sol';

// Renderer + SVG.sol + Utils.sol from hot-chain-svg.
// Modified to fit the project.
// https://github.com/w1nt3r-eth/hot-chain-svg

contract Renderer {

    function render(bytes memory hash, uint256 _tokenId) public pure returns (string memory) {
        uint256 midPoint = uint256(toUint8(hash,0))*300/256; // 0 - 299
        uint256 midPoint2 = uint256(toUint8(hash,1))*300/256; // 0 - 299
        uint256 gap = 10 + uint256(toUint8(hash,2))/4; // 0 - 63 
        uint256 shiftTopY = 300 - midPoint;
        uint256 shiftBottomY = 300 + midPoint;

        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="300" style="background:#000">',
                definitions(hash, _tokenId),
                room(shiftTopY, shiftBottomY),
                gradientRects(shiftTopY, shiftBottomY),
                stars(shiftTopY, shiftBottomY),
                polygons(gap, midPoint, midPoint2),
                '</svg>'
            );
    }

    function definitions(bytes memory hash, uint256 _tokenId) public pure returns (string memory) {
        return string.concat(gradients(), filters(hash, _tokenId));
    }

    /*
    To emphasise the feeling of the horizon disappearing.
    */
    function gradients() public pure returns (string memory) {
        return string.concat(
                svg.linearGradient(
                    string.concat(svg.prop('id', 'topGradient'),svg.prop('gradientTransform', 'rotate(90)')),
                    string.concat(svg.gradientStop(80, 'white',svg.prop('stop-opacity', '0')),svg.gradientStop(100, 'white', svg.prop('stop-opacity', '1')))
                )
        );
    }

    function filters(bytes memory hash, uint256 _tokenId) public pure returns (string memory) {
        string memory roomBF = generateBaseFrequency(hash, 3, 4, ['0.0', '0.00', '0.000']);
        string memory starsBF = generateBaseFrequency(hash, 5, 6, ['0.', '0.0', '0.00']);
        string memory starsOctaves = utils.uint2str(1 + uint256(toUint8(hash,7))*4/256); // 1 - 4

        string memory roomSeed = utils.uint2str(uint256(toUint8(hash,8))*uint256(toUint8(hash,9))*uint256(toUint8(hash,10))); // 0 - 16581375
        string memory starSeed = utils.uint2str(uint256(toUint8(hash,11))*uint256(toUint8(hash,12))*uint256(toUint8(hash,13))); // 0 - 16581375

        return string.concat(
            svg.filter(
                svg.prop('id','room'),
                string.concat(
                    svg.el('feTurbulence', string.concat(svg.prop('baseFrequency', roomBF),svg.prop('seed', roomSeed), svg.prop('result', 'turb'))),
                    svg.el('feColorMatrix', svg.prop('values', generateColorMatrix(hash, _tokenId)))
                )
            ),
            svg.filter(
                svg.prop('id', 'stars'),
                string.concat(
                    svg.el('feTurbulence', string.concat(svg.prop('type', 'fractalNoise'), svg.prop('numOctaves', starsOctaves), svg.prop('baseFrequency', starsBF), svg.prop('seed', starSeed), svg.prop('result', 'turb'))),
                    svg.el('feColorMatrix', svg.prop('values', '15 0 0 0 0 0 15 0 0 0 0 0 15 0 0 0 0 0 -15 5'))
                )
            )
        );
    }

    function generateBaseFrequency(bytes memory hash, uint256 index1, uint index2, string[3] memory decimalStrings) public pure returns (string memory) {
        string memory strNr = utils.uint2str(1 + uint256(toUint8(hash,index1))*1000/256); // 1 - 997 (ish)
        uint256 dec = uint256(toUint8(hash, index2))*3/256; // 0 - 2
        string memory bf = string.concat(decimalStrings[dec], strNr);
        return bf;
    }

    /* DRAWING SVG */
    function room(uint256 shiftTopY, uint256 shiftBottomY) public pure returns (string memory) {
        string memory rectProps = string.concat(
            svg.prop('width', '300'),
            svg.prop('height', '300'),
            svg.prop('filter', 'url(#room)')
        );
        string memory topTranslate = string.concat('translate(0,-',utils.uint2str(shiftTopY+30),')'); // move it up to horizon
        string memory bottomTranslate = string.concat('translate(0,', utils.uint2str(shiftBottomY+30),') scale(-1,1) rotate(180)'); // move it down to floor of horizon, flip and rotate to mirror

        return string.concat(
            svg.rect(
                string.concat(
                    rectProps,
                    svg.prop('transform', topTranslate) 
                )
            ),
            svg.rect(
                string.concat(
                    rectProps,
                    svg.prop('transform', bottomTranslate)
                )
            )
        );
    }

    function generateColorMatrix(bytes memory hash, uint256 _tokenId) public pure returns (string memory) {
        string memory strMatrix;

        for(uint i = 0; i<20; i+=1) {
            // re-uses entropy
            uint matrixOffset = uint256(toUint8(hash, i))/4; // 0 - 64
            uint negOrPos = toUint8(hash, i); // 0 - 255

            if(i == 18) {
                // the minimalism factor is defined by the alpha/alpha offset in the color matrix.
                // positive == changing to more colour
                // negative == taking colour away
                // the range is +64 -> -64 (128 digits)
                // max minimalism arrives at 1m mints.
                uint256 diff = generateMinimalismFactor(hash, i, _tokenId);

                // signed ints would've been better, but using unsigned<->string utils, so just manually adding pos/neg signs.
                string memory modStr;
                if (diff > 64) {
                   modStr = string.concat("-", utils.uint2str(diff-64), ' ');
                } else {
                   modStr = string.concat(utils.uint2str(64-diff), ' ');
                }

                strMatrix = string.concat(strMatrix, modStr); 

            } else if(i==4 || i == 9 || i== 14 || i == 19) {
                strMatrix = string.concat(strMatrix, '1 '); // end multiplier of channels (should be linear change, not multiplied)
            } else if(negOrPos < 128) { // random chance of adding or taking away colour (or alpha) from rgba
                strMatrix = string.concat(strMatrix, utils.uint2str(matrixOffset), ' ');
            } else {
                strMatrix = string.concat(strMatrix, '-', utils.uint2str(matrixOffset), ' ');
            }
        }
        return strMatrix;
    }

    /*
    A number in between 0 - 128, where 0 is most maximal. No attempt at minimalism.
    128 is the most minimal (given the constraints of the artist).

    It becomes more likely to produce a more minimal painting as it approaches 1 million.
    eg, at mint 1 -> minimalism factor is 0.
    at mint 1,000,000 -> minimalism factor could be between 0 - 128.
    */
    function generateMinimalismFactor(bytes memory hash, uint256 index, uint256 _tokenId) public pure returns (uint256) {
        uint256 rnr = uint256(toUint8(hash, index))/2 + 1; // 1 - 128

        uint256 diff;
        if(_tokenId > 1000000) { 
            diff = rnr; 
        } else {
            diff = _tokenId*rnr/1000000;
        }

        return diff;
    }

    /*
    Some distant stars or nearby galactic nebula. Adds a shine to the room of infinite paintings.
    */
    function stars(uint256 shiftTopY, uint256 shiftBottomY) public pure returns (string memory) {
        string memory rectProps = string.concat(
            svg.prop('width', '300'),
            svg.prop('height', '300'),
            svg.prop('filter', 'url(#stars)')
        );
        string memory topTranslate = string.concat('translate(0,-',utils.uint2str(shiftTopY+30),')');
        string memory bottomTranslate = string.concat('translate(0,', utils.uint2str(shiftBottomY+30),') scale(-1,1) rotate(180)');
        return string.concat(
                svg.rect(
                    string.concat(
                        rectProps, 
                        svg.prop('transform', topTranslate)
                    )
                ),
                svg.rect(
                    string.concat(
                        rectProps, 
                        svg.prop('transform', bottomTranslate)
                    )
                )
        );
    }

    function gradientRects(uint256 shiftTopY, uint256 shiftBottomY) public pure returns (string memory) {
        return string.concat(
                svg.rect(string.concat(svg.prop('width', '300'), svg.prop('height', '300'), svg.prop('fill', 'url(#topGradient)'), svg.prop('transform', string.concat('translate(0,-',utils.uint2str(shiftTopY),')')))),
                svg.rect(string.concat(svg.prop('width', '300'), svg.prop('height', '300'), svg.prop('fill', 'url(#topGradient)'), svg.prop('transform', string.concat('translate(0,', utils.uint2str(shiftBottomY),') scale(-1,1) rotate(180)'))))
        );
    }

    /*
    The polygons are to give the feeling of a room/area stretching into the horizon.
    If the background canvas is white, it fulfills this better.
    If the background is dark, however, the corner polygons make the polygons feel more like it ends in the corners. More artistic than the idea of a line fading into the horizon.
    It's a subtle point to emphasise that the context of the infinite painting matters where it is viewed.
    The initial intent goal was for it to be merely infinite, but instead of taking out the corner lines, I've kept it in to change the feeling of the painting based on what background canvas is used.
    */
    function polygons(uint256 gap, uint256 midPoint, uint256 midPoint2) public pure returns (string memory) {
        uint256[8] memory polyPoints1 = [gap, 0, 0, 0, 0, gap, midPoint2, midPoint];
        uint256[8] memory polyPoints2 = [0, 300-gap, 0, 300, gap, 300, midPoint2, midPoint];
        uint256[8] memory polyPoints3 = [300-gap, 0, 300, 0, 300, gap, midPoint2, midPoint];
        uint256[8] memory polyPoints4 = [300, 300-gap, 300, 300, 300-gap, 300, midPoint2, midPoint];

        return string.concat(
                polygon(polyPoints1), 
                polygon(polyPoints2), 
                polygon(polyPoints3), 
                polygon(polyPoints4)
        );
    }

    function polygon(uint256[8] memory points) public pure returns (string memory) {
        string memory poly = string.concat(utils.uint2str(points[0]),',',utils.uint2str(points[1]),' ',utils.uint2str(points[2]),',',utils.uint2str(points[3]),' ',utils.uint2str(points[4]),',',utils.uint2str(points[5]),' ',utils.uint2str(points[6]),',',utils.uint2str(points[7]));
        return svg.el('polygon', 
            string.concat(
                svg.prop('points', poly),
                svg.prop('fill', 'none'),
                svg.prop('stroke', 'white')
            )
        );
    }

    /* HELPER */

    // helper function for generation
    // from: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol 
    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_start + 1 >= _start, "toUint8_overflow");
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint; 

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }
        return tempUint;
    }
}

contract CollectionDescriptor {

    Renderer public renderer;

    constructor() {
        renderer = new Renderer();
    }

    function generateName(uint nr) public pure returns (string memory) {
        return string(abi.encodePacked('Infinite Painting #', utils.uint2str(nr)));
    }

    /*
    While the painting has many random variables (using & re-using ~34 random variables), the only trait to log and keep track of is the minimalism factor.
    The rest should be collected/desired based on aesthetic appeal.
    */
    function generateTraits(bytes memory hash, uint256 tokenId) public view returns (string memory) {
        uint256 minimalFactor = renderer.generateMinimalismFactor(hash, 18, tokenId); 
        string memory traitType = '{"trait_type": "Minimalism Factor", "value":';
        string memory traitValue = string.concat('"', utils.uint2str(minimalFactor), '"}');

        return string(abi.encodePacked(
            '"attributes": [',
            traitType,
            traitValue,
            ']'
        ));
    }

    function generateImage(bytes memory hash, uint256 tokenId) public view returns (string memory) {
        return renderer.render(hash, tokenId);
    } 
}