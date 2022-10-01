//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import './svg.sol';
import './utils.sol';

contract Words {

    // 33
    string[] public rareActions = [
        'DIVINATED CORALS',
        'PLANTED RUNES',
        'LED EXODUS',
        'CRAFTED IRIDESCENCE',
        'ACCUMULATED DUNES',
        'DECIPHERED CAVES',
        'STOLE GUILT',
        'WROTE SAND',
        'BRAIDED GEMS',
        'TOUCHED LIGHTNING',
        'SPARKED AWAKENING',
        'TORE FEAR',
        'ALIGNED COLLECTIVE',
        'HACKED CONFUSION',
        'STEERED WEBS',
        'GUIDED MOVEMENTS',
        'PROGRESSED PERCEPTION',
        'ABSORBED THOUGHT',
        'CONSTRUCTED EMPIRES',
        'BYPASSED EGOS',
        'RETRIEVED RIDDLES',
        'MET FROGS',
        'TURNED PHYSICS',
        'SLEPT AURAS',
        'FOUND SILLINESS',
        'COOKED SURVEILLANCE',
        'BUILT BIO-ARMOUR',
        'ALLEVIATED COGNITION',
        'INTENSIFIED LUCIDITY',
        'PAINTED INTERBEINGS',
        'DRANK CULTURES',
        'EMERGENT KNOWING',
        'SWEPT SUNSHINE'
    ];

    // 62
    string[] public actions = [
        'LENGTHENED PLANETS',
        'BREATHED SONIC',
        'BEAMED RHYTHMS',
        'MERGED CONTENTION',
        'DEPLOYED PUZZLES',
        'RECREATED MYTHS',
        'GREW ROOTS',
        'UNDERSTOOD RAIN',
        'REVITALISED ELECTRICITY',
        'THOUGHT CRYSTAL',
        'SURPRISED BEINGS',
        'PLAYED INFINITELY',
        'SNUGGLED DANGER',
        'PINCHED MAGMA',
        'JUGGLED MOMENTS',
        'SPOKE WATER',
        'SCULPTED SOUND',
        'BEGAN BEGINNINGS',
        'BECAME ECOLOGY',
        'TASTED LIGHT',
        'THOUGHT STORMS',
        'CIRCULATED GRAVITY',
        'SWAM COLOURFULLY',
        'GALVANISED BASS',
        'HEARTENED ROCKS',
        'KINDLED EARTHSTORY',
        'AWAKENED GRIMOIRE',
        'INCITED ABUNDANCE',
        'EVOLVED SEEDS',
        'DANCED COSMIC',
        'REGENERATED',
        'FLIRTED FLOWERS',
        'CHERISHED WINTER',
        'TOYED RIVERS',
        'CREATED BEAUTY',
        'EMBOLDENED DUST',
        'LOVED MOSS',
        'DANCED WORLDS',
        'WHISPERED DARKNESS',
        'CODED DIVINITY',
        'LAUGHED DEEPLY',
        'DREAMED FUNGI',
        'VENTURED DEPTHS',
        'WANDERED FORESTS',
        'SCULPTED SUN',
        'SUBVERTED ECLIPSE',
        'EMBODIED MOUNTAIN',
        'EXPLORED DIVINITY',
        'DEEPENED STILLNESS',
        'REFLECTED STARS',
        'UNITED FRIENDS',
        'BEFRIENDED DARKNESS',
        'FELT UNIVERSAL',
        'INITIATED EARTHSTORY',
        'EMBRACED ALL',
        'ROAMED UNIVERSE',
        'NOURISHED DEATH',
        'FLOATED CLOUDS',
        'MOVED EVERYBODY',
        'FELT COSMIC',
        'SHOOK TRAUMA',
        'HEALED PAIN'
    ];

    struct WordDetails {
        string lineX1;
        string lineX2;
        string lineY;
        string textX;
        string textY;
        string textAnchor;
    }

    function whatIveDone(bytes memory hash, bool randomMint) public view returns (string memory) {
        string memory wordList;

        uint256[3][10] memory indices;
        
        uint256 leftY = utils.getLeftY(hash); // 100 - 116
        uint256 rightY = utils.getRightY(hash); // 100 - 116
        uint256 diffLeft = utils.getDiffLeft(hash); // 10 - 33
        uint256 diffRight = utils.getDiffRight(hash); // 10 - 33

        (,, indices) = utils.getIndices(hash, randomMint);
        WordDetails memory details;

        for(uint i; i < 10; i+=1) {
            // 10 slots. 5 a side.
            // words are drawn left-right, then down.
            uint y;
            if(i % 2 == 0) {
                details.lineX1 = '10'; //x1
                details.lineY = utils.uint2str(leftY-3); //y1, y2
                details.lineX2 = '150'; //x2
                details.textY = utils.uint2str(leftY);
                details.textX = '10';
                details.textAnchor = 'start';
                y = leftY;

                leftY += diffLeft;
            } else {
                details.lineX1 = '150'; //x1
                details.lineY = utils.uint2str(rightY-3); //y1, y2
                details.lineX2 = '280'; //x2
                details.textY = utils.uint2str(rightY);
                details.textX = '290';
                details.textAnchor = 'end';
                y = rightY;

                rightY += diffRight;
            }

            if(indices[i][0] == 1) { // if the slot is assigned
                wordList = string.concat(wordList, 
                        singularAction(details, indices[i][1], indices[i][2], randomMint)
                );
            }
        }

        return wordList;
    }

    function singularAction(WordDetails memory details, uint256 rarity, uint256 wordIndex, bool randomMint) public view returns (string memory) {
        string memory dottedProp;
        string memory action;
        if(randomMint && rarity == 1) { // if a rare word
            action = rareActions[wordIndex];
            dottedProp = svg.prop('stroke-dasharray', '4'); 
        } else {
            action = actions[wordIndex];
        }
        return string.concat(
            svg.el('line', string.concat(svg.prop('x1', details.lineX1), svg.prop('y1', details.lineY), svg.prop('x2', details.lineX2), svg.prop('y2', details.lineY), svg.prop('stroke', 'black'), dottedProp)),
            svg.el('text', string.concat(
            svg.prop('text-anchor', details.textAnchor),
            svg.prop('x', details.textX),
            svg.prop('y', details.textY),
            svg.prop('font-family', 'Helvetica'),
            svg.prop('fill', 'black'),
            svg.prop('font-weight', 'bold'),
            svg.prop('font-size', '6'),
            svg.prop('filter', 'url(#solidTextBGFilter)')),
            action
        ));
    }
}