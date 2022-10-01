// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

// Renderer + SVG.sol + Utils.sol from hot-chain-svg.
// Modified to fit the project.
// https://github.com/w1nt3r-eth/hot-chain-svg

import "./Words.sol";
import "./Definitions.sol";

contract CollectionDescriptor {

    Words public words;
    Definitions public defs;

    constructor() {
        words = new Words();
        defs = new Definitions();
    }

    function render(uint256 _tokenId, bool randomMint) internal view returns (string memory) {
        bytes memory hash = abi.encodePacked(bytes32(_tokenId));

        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="300" style="background:#fff">',
                defs.defs(hash),
                craftSand(hash),
                cutOut(hash, randomMint),
                capsuleOutline(),
                '</svg>'
            );
    }

    /* RE-USABLE SHAPES */
    function sandRect(string memory y, string memory h, string memory fill, string memory opacity) internal pure returns (string memory) {
        return svg.rect(
            string.concat(
                svg.prop('width', '300'),
                svg.prop('y',y),
                svg.prop('height',h),
                svg.prop('fill',fill),
                svg.prop('stroke','black'),
                svg.prop('filter','url(#sandFilter)'),
                svg.prop('opacity', opacity)
            )
        );        
    }

    /* CONSTRUCTIONS */
    function craftSand(bytes memory hash) internal pure returns (string memory) {
        string memory sandRects = '<rect width="100%" height="100%" filter="url(#fineSandFilter)"/> '; // background/fine sand

        uint amount = utils.getAmount(hash); // 2 - 18
        uint range = utils.getRange(hash);
        uint height; // = 0
        uint y; // = 0
        uint shift = 3;
        uint colour =  utils.getColour(hash);// 0 - 360
        uint cShift = utils.getColourShift(hash); // 0 - 255
        string memory opacity = "1";
        for (uint i = 1; i <= amount; i+=1) {
            y+=height;
            if(i % 2 == 0) {
                height = range*shift/2 >> shift;
                shift += 1;
            }
            opacity = "1";
            if ((y+colour) % 5 == 0) { opacity = "0"; }
            sandRects = string.concat(
                sandRects,
                sandRect(utils.uint2str(y), utils.uint2str(height), string.concat('hsl(',utils.uint2str(colour),',70%,50%)'), opacity)
            );
            colour+=cShift;
        }

        return sandRects;
    }

    function capsuleOutline() internal pure returns (string memory) {
        return string.concat(
            // top half of capsule
            svg.rect(string.concat(svg.prop('x', '111'), svg.prop('y', '50'), svg.prop('width', '78'), svg.prop('height', '150'), svg.prop('ry', '40'), svg.prop('rx', '40'), svg.prop('mask', 'url(#cutoutMask)'), svg.prop('clip-path', 'url(#clipBottom)'))),
            // bottom half of capsule
            svg.rect(string.concat(svg.prop('x', '113'), svg.prop('y', '50'), svg.prop('width', '74'), svg.prop('height', '205'), svg.prop('ry', '35'), svg.prop('rx', '50'), svg.prop('mask', 'url(#cutoutMask)'))),
            // crossbar of capsule 
            svg.rect(string.concat(svg.prop('x', '111'), svg.prop('y', '150'), svg.prop('width', '78'), svg.prop('height', '4'))),
            // top reflection
            svg.rect(string.concat(svg.prop('x', '115'), svg.prop('y', '45'), svg.prop('width', '70'), svg.prop('height', '40'), svg.prop('ry', '100'), svg.prop('rx', '10'), svg.prop('fill', 'white'), svg.prop('opacity', '0.4'), svg.prop('mask', 'url(#topReflectionMask)'))),
            // long reflection
            svg.rect(string.concat(svg.prop('x', '122'), svg.prop('y', '55'), svg.prop('width', '56'), svg.prop('height', '184'), svg.prop('ry', '30'), svg.prop('rx', '30'), svg.prop('fill', 'white'), svg.prop('opacity', '0.4'))),
            // drop shadow
            svg.rect(string.concat(svg.prop('x', '115'), svg.prop('y', '180'), svg.prop('width', '70'), svg.prop('height', '70'), svg.prop('ry', '30'), svg.prop('rx', '30'), svg.prop('filter', 'url(#dropShadowFilter)'), svg.prop('clip-path', 'url(#clipShadow)')))
        );
    }

    function cutOut(bytes memory hash, bool randomMint) internal view returns (string memory) {
        return svg.el('g', svg.prop('mask', 'url(#cutoutMask)'),
            string.concat(
                svg.whiteRect(),
                words.whatIveDone(hash, randomMint)
            )
        );
    }

    function generateName(uint nr) public pure returns (string memory) {
        return string(abi.encodePacked('Capsule #', utils.substring(utils.uint2str(nr),0,8)));
    }
    
    function generateTraits(uint256 tokenId, bool randomMint) public view returns (string memory) {
        bytes memory hash = abi.encodePacked(bytes32(tokenId));
        (uint256 rareCount, uint256 allCount, uint256[3][10] memory indices) = utils.getIndices(hash, randomMint);

        string memory nrOfWordsTrait = createTrait("Total Experiences", utils.uint2str(allCount));
        string memory nrOfRareWordsTrait = createTrait("Rare Experiences", utils.uint2str(rareCount));
        string memory slots;
        string memory typeOfMint;
        
        if(randomMint) {
            typeOfMint = createTrait("Type of Mint", "Random");
        } else {
            typeOfMint = createTrait("Type of Mint", "Chosen Seed");
        }

        for(uint i; i < 10; i+=1) {
            if(indices[i][0] == 1) { // slot is assigned or not
                string memory slotPosition = string.concat("Slot ", utils.uint2str(i));
                string memory action;
                if(indices[i][1] == 1) { // there's a rare word there or not
                    action = words.rareActions(indices[i][2]);
                } else {
                    action = words.actions(indices[i][2]);
                }

                slots = string.concat(slots, ",", createTrait(slotPosition, action));
            }
        }

        return string(abi.encodePacked(
            '"attributes": [',
            nrOfWordsTrait,
            ",",
            nrOfRareWordsTrait,
            ",",
            typeOfMint,
            slots,
            ']'
        ));
    }

    function createTrait(string memory traitType, string memory traitValue) internal pure returns (string memory) {
        return string.concat(
            '{"trait_type": "',
            traitType,
            '", "value": "',
            traitValue,
            '"}'
        );
    }

    function generateImage(uint256 tokenId, bool randomMint) public view returns (string memory) {
        return render(tokenId, randomMint);
    } 
}