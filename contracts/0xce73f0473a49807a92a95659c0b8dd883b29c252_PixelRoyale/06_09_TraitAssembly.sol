// SPDX-License-Identifier: MIT
// www.PixelRoyale.xyz
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";

library TraitAssembly {
    
    //---------- ACCESSORY ASSEMBLY - WITH ACCESSORY SVGs ----------//
    function choseA(uint32 _seed) public pure returns (string memory _aString, string memory _aJson) {
        string[13] memory _traitArray = ["Flower Crown", "Night Vision", "Trauma", "Sleek Curl", "Twin Tails", "Red Rag", "Blue Rag", "Snapback", "Crown", "One Peace", "Red Oni", "Blue Oni", "Clown"];
        string memory _trait = _traitArray[_seed%12];
        string memory soulCol =  Strings.toString((_seed%72)*5);
        string memory inverseCol = Strings.toString((((_seed%72)*5)+180)%360);
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[0]))) {
            _aString = '<polygon points="3,3 8,3 8,4 9,4 9,3 13,3 13,4 14,4 14,5 13,5 13,6 8,6 8,5 7,5 7,6 3,6 3,5 2,5 2,4 3,4" fill="hsl(102, 75%, 58%)"/><polygon points="5,3 11,3 11,4 12,4 12,5 11,5 11,6 10,6 10,5 9,5 9,4 10,4 10,3 6,3 6,4 7,4 7,5 6,5 6,6 5,6 5,5 4,5 4,4 5,4" fill="hsl(0, 100%, 100%)"/><polygon points="5,4 11,4 11,5 10,5 10,4 6,4 6,5 5,5 5,4" fill="hsl(48, 100%, 57%)"/>';
        }
        else if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[1]))) {
            _aString = '<polygon points="4,2 6,2 6,3 7,3 7,2 9,2 9,3 10,3 10,2 12,2 12,3 13,3 13,5 14,5 14,6 10,6 10,5 6,5 6,6 2,6 2,5 3,5 3,3 4,3" fill="hsl(0,0%,0%)"/><polygon points="4,3 12,3 12,5 10,5 10,3 9,3 9,4 7,4 7,3 6,3 6,5 4,5" fill="hsl(102, 73%, 64%)"/>';
        }
        else if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[2]))) {
            _aString = '<polygon points="9,2 11,2 11,5 10,5 10,3 9,3" fill="hsl(352, 100%, 41%)"/>'; 
        }
        else if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[3]))) {
            _aString = string(abi.encodePacked('<polygon points="4,1 12,1 12,2 13,2 13,7 12,7 12,6 11,6 11,4 8,4 8,5 9,5 9,6 7,6 7,4 5,4 5,6 4,6 4,7 3,7 3,2 4,2" fill="hsl(',inverseCol,', 80%, 60%)"/>')); 
        }
        else if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[4]))) {
            _aString = string(abi.encodePacked('<polygon points="5,1 11,1 11,2 12,2 12,3 13,3 13,4 14,4 14,5 15,5 15,6 16,6 16,10 15,10 15,9 14,9 14,6 13,6 13,7 12,7 12,6 11,6 11,5 10,5 10,6 9,6 9,5 8,5 8,6 6,6 6,5 5,5 5,6 4,6 4,7 3,7 3,6 2,6 2,9 1,9 1,10 0,10 0,6 1,6 1,5 2,5 2,4 3,4 3,3 4,3 4,2 5,2" fill="hsl(',inverseCol,', 80%, 60%)"/><polygon points="2,4 3,4 14,4 14,6 13,6 13,4 3,4 3,6 2,6 " fill="hsl(',soulCol,', 40%, 60%)"/>'));
        }
        else if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[5]))) {
            _aString = '<polygon points="3,2 4,2 4,1 12,1 12,2 13,2 13,5 2,5 2,6 1,6 1,5 2,5 2,4 1,4 1,3 2,3 2,4 3,4" fill="hsl(0, 75%, 50%)"/>';
        }
        else if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[6]))) {
            _aString = '<polygon points="3,2 4,2 4,1 12,1 12,2 13,2 13,5 2,5 2,6 1,6 1,5 2,5 2,4 1,4 1,3 2,3 2,4 3,4" fill="hsl(225, 75%, 50%)"/>';
        }
        else if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[7]))) {
            _aString = string(abi.encodePacked('<polygon points="3,4 3,2 4,2 4,1 12,1 12,2 13,2 13,5 2,5 1,5 1,4" fill="hsl(',soulCol,', 75%, 50%)"/><polygon points="7,4 7,3 8,3 8,2 10,2 10,3 11,3 11,4" fill="hsl(',soulCol,', 75%, 25%)"/>'));
        }
        else if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[8]))) {
            _aString = '<polygon points="3,4 4,4 4,3 5,3 5,4 6,4 6,3 7,3 7,2 9,2 9,3 10,3 10,4 11,4 11,3 12,3 12,4 13,4 13,5 3,5 " fill="hsl(45, 100%, 50%)"/>';
        }
        else if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[9]))) {
            _aString = '<polygon points="1,4 3,4 3,2 4,2 4,1 12,1 12,2 13,2 13,4 15,4 15,5 1,5" fill="hsl(45, 100%, 50%)"/><rect x="3" y="3" width="10" height="1" fill="hsl(0,100%,50%)"/>';
        }
        else if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[10]))) {
            _aString = '<polygon points="12,5 12,3 13,3 13,2 14,2 14,1 15,1 15,4 14,4 14,5" fill="hsl(0,100%,50%)"/>';
        }
        else if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[11]))) {
            _aString = '<polygon points="4,5 4,3 3,3 3,2 2,2 2,1 1,1 1,4 2,4 2,5" fill="hsl(225,100%,50%)"/>';
        }
        else if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[12]))) {
            _aString = string(abi.encodePacked('<polygon points="1,1 2,1 2,2 6,2 6,1 7,1 7,0 9,0 9,1 10,1 10,2 14,2 14,1 15,1 15,4 14,4 14,5 12,5 12,3 11,3 11,2 5,2 5,3 4,3 4,5 2,5 2,4 1,4" fill="hsl(',soulCol,',75%,45%)"/>'));
        }
        return(_aString,_aJson = _trait);
    }
    
    //---------- EYES ASSEMBLY - WITH EYE SVGs ----------//
    function choseE(uint32 _seed) public pure returns (string memory _eString, string memory _eJson) {
        string[17] memory _traitArray = ["Passive", "Sane", "Wary", "Fine", "Shut", "Glee", "Cool", "Tough", "Archaic", "Sly", "Sharp", "Sad", "Indifferent", "Focused", "Gloomy", "Abnormal", "Gem"];
        string memory _trait = _traitArray[_seed%16];
        string memory soulCol =  Strings.toString((_seed%72)*5);
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[0]))) {
            _eString = string(abi.encodePacked('<polygon points="5,7 11,7 11,9 9,9 9,7 7,7 7,9 5,9" fill="hsl(180,100%,100%)"/><polygon points="6,7 11,7 11,9 10,9 10,7 7,7 7,9 6,9" fill="hsl(',soulCol,',40%,60%)"/>'));
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[1]))) {
            _eString = string(abi.encodePacked('<polygon points="5,8 11,8 11,9 9,9 9,8 7,8 7,9 5,9" fill="hsl(180,100%,100%)"/><polygon points="5,8 10,8 10,9 9,9 9,8 6,8 6,9 5,9" fill="hsl(',soulCol,',40%,60%)"/><polygon points="5,6 11,6 11,7 9,7 9,6 7,6 7,7 5,7" fill="hsl(180,0%,0%)"/>'));
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[2]))) {
            _eString = string(abi.encodePacked('<polygon points="5,8 11,8 11,9 9,9 9,8 7,8 7,9 5,9" fill="hsl(180,100%,100%)"/><polygon points="6,8 11,8 11,9 10,9 10,8 7,8 7,9 6,9" fill="hsl(',soulCol,',40%,60%)"/><polygon points="5,5 6,5 6,6 11,6 11,7 9,7 9,6 7,6 7,7 6,7 6,6 5,6" fill="hsl(180,0%,0%)"/>'));
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[3]))) {
            _eString = string(abi.encodePacked('<polygon points="4,8 5,8 5,7 11,7 11,8 12,8 12,9 9,9 9,7 7,7 7,9 4,9" fill="hsl(180,0%,0%)"/><polygon points="5,8 11,8 11,9 9,9 9,8 7,8 7,9 5,9" fill="hsl(',soulCol,',40%,60%)"/><polygon points="6,8 11,8 11,9 10,9 10,8 7,8 7,9 6,9" fill="hsl(180,0%,0%)"/>'));
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[4]))) {
            _eString = '<polygon points="4,7 5,7 5,8 6,8 6,7 10,7 10,8 11,8 11,7 12,7 12,8 11,8 11,9 10,9 10,8 9,8 9,7 7,7 7,8 6,8 6,9 5,9 5,8 4,8" fill="hsl(180,0%,0%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[5]))) {
            _eString = '<polygon points="4,8 5,8 5,7 6,7 6,8 10,8 10,7 11,7 11,8 12,8 12,9 11,9 11,8 10,8 10,9 9,9 9,8 7,8 7,9 6,9 6,8 5,8 5,9 4,9" fill="hsl(180,0%,0%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[6]))) {
            _eString = '<polygon points="4,7 12,7 12,8 11,8 11,9 9,9 9,8 7,8 7,9 5,9 5,8 4,8" fill="hsl(180,0%,0%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[7]))) {
            _eString = string(abi.encodePacked('<rect x="5" y="8" width="2" height="1" fill="hsl(180,100%,100%)"/><rect x="5" y="8" width="1" height="1" fill="hsl(',soulCol,',40%,60%)"/><polygon points="5,3 6,3 6,4 7,4 7,5 8,5 8,6 9,6 9,7 11,7 11,9 12,9 12,10 11,10 11,9 9,9 9,8 5,8 5,7 7,7 7,8 9,8 9,7 8,7 8,6 7,6 7,5 6,5 6,4 5,4" fill="hsl(180,0%,0%)"/>'));
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[8]))) {
            _eString = string(abi.encodePacked('<polygon points="5,8 11,8 11,9 9,9 9,8 7,8 7,9 5,9" fill="hsl(180,100%,100%)"/><polygon points="5,8 10,8 10,9 9,9 9,8 6,8 6,9 5,9" fill="hsl(',soulCol,',40%,60%)"/><rect x="4" y="7" width="8" height="1" fill="hsl(180,0%,0%)"/>'));
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[9]))) {
            _eString = string(abi.encodePacked('<rect x="4" y="6" width="8" height="3" fill="hsl(180,0%,0%)"/><polygon points="5,7 11,7 11,8 9,8 9,7 7,7 7,8 5,8" fill="hsl(180,100%,100%)"/><polygon points="6,7 11,7 11,8 10,8 10,7 7,7 7,8 6,8" fill="hsl(',soulCol,',40%,60%)"/>'));
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[10]))) {
            _eString = string(abi.encodePacked('<polygon points="5,7 5,6 7,6 7,7 9,7 9,6 11,6 11,7 12,7 12,8 11,8 11,9 9,9 9,8 7,8 7,9 5,9 5,8 4,8 4,7" fill="hsl(180,0%,0%)"/><polygon points="5,7 11,7 11,8 9,8 9,7 7,7 7,8 5,8" fill="hsl(',soulCol,',40%,60%)"/>'));
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[11]))) {
            _eString = '<polygon points="11,8 11,10 10,10 10,8 6,8 6,12 5,12 5,8" fill="hsl(188, 39%, 58%)"/><polygon points="5,7 11,7 11,8 9,8 9,7 7,7 7,8 5,8" fill="hsl(180,0%,0%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[12]))) {
            _eString = string(abi.encodePacked('<polygon points="5,6 6,6 6,9 10,9 10,6 11,6 11,9 5,9" fill="hsl(180,0%,0%)"/><polygon points="4,7 12,7 12,8 9,8 9,7 7,7 7,8 4,8" fill="hsl(180,100%,100%)"/><polygon points="5,7 6,7 6,8 10,8 10,7 11,7 11,8 5,8" fill="hsl(',soulCol,',40%,60%)"/>'));
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[13]))) {
            _eString = string(abi.encodePacked('<polygon points="4,7 12,7 12,8 9,8 9,7 7,7 7,8 4,8" fill="hsl(180,0%,0%)"/><polygon points="4,8 12,8 12,9 9,9 9,8 7,8 7,9 4,9" fill="hsl(180,100%,100%)"/><polygon points="5,8 6,8 6,9 10,9 10,8 11,8 11,9 5,9" fill="hsl(',soulCol,',40%,60%)"/>'));
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[14]))) {
            _eString = string(abi.encodePacked('<polygon points="4,5 5,5 5,6 6,6 6,7 10,7 10,6 11,6 11,5 12,5 12,7 13,7 13,8 12,8 12,10 11,10 11,9 10,9 10,8 9,8 9,7 7,7 7,8 6,8 6,9 5,9 5,10 4,10 4,8 3,8 3,7 4,7 " fill="hsl(180,0%,0%)"/><polygon points="4,7 12,7 12,8 10,8 10,7 6,7 6,8 4,8" fill="hsl(180,100%,100%)"/><polygon points="5,7 6,7 6,8 11,8 11,7 12,7 12,8 5,8" fill="hsl(',soulCol,',40%,60%)"/>'));
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[15]))) {
            _eString = '<polygon points="5,8 6,8 6,9 10,9 10,7 11,7 11,9 10,9 5,9" fill="hsl(180,0%,0%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[16]))) {
            _eString = string(abi.encodePacked('<polygon points="5,7 11,7 11,9 9,9 9,7 7,7 7,9 5,9 " fill="hsl(180,100%,100%)"/><polygon points="5,8 6,8 6,7 7,7 7,8  10,8 10,7 11,7 11,8 10,8 10,9 9,9 9,8 6,8 6,9 5,9" fill="hsl(',soulCol,',40%,60%)"/>'));
        }
        return(_eString,_eJson = _trait);
    }

    //---------- MOUTH ASSEMBLY - WITH MOUTH SVGs ----------//
    function choseM(uint32 seed) public pure returns (string memory _mString, string memory _mJson) {
        string[18] memory _traitArray = ["Smile", "Rabbit", "Frown", "Jeez", "Deez", "Grin", "Hungry", "Hillbilly", "Yikes", "Dumber", "Cigarette", "Puke", "Raw", "Tongue", "Surprised", "Stunned", "Chew", "Respirator"]; 
        string memory _trait = _traitArray[seed%17];
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[0]))) {
            _mString = '<polygon points="6,11 5,11 5,10 6,10 6,11 10,11 10,10 11,10 11,11 10,11 10,12 6,12" fill="hsl(180,0%,0%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[1]))) {
            _mString = '<polygon points="6,11 5,11 5,10 6,10 6,11 10,11 10,10 11,10 11,11 10,11 10,12 6,12" fill="hsl(180,0%,0%)"/><polygon points="7,13 7,12 9,12 9,13" fill="hsl(180,100%,100%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[2]))) {
            _mString = '<polygon points="6,12 5,12 5,11 6,11 6,10 10,10 10,12 11,12 11,11 10,11 10,11 6,11 " fill="hsl(180,0%,0%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[3]))) {
            _mString = '<rect x="7" y="10" width="2" height="1" fill="hsl(180,0%,0%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[4]))) {
            _mString = '<rect x="5" y="10" width="6" height="1" fill="hsl(180,0%,0%)"/><rect x="6" y="10" width="1" height="1" fill="hsl(180,100%,100%)"/><rect x="9" y="10" width="1" height="1" fill="hsl(180,100%,100%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[5]))) {
            _mString = '<polygon points="7,11 6,11 6,10 7,10 7,11 9,11 9,10 10,10 10,11 9,11 9,12 7,12" fill="hsl(180,0%,0%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[6]))) {
            _mString = '<polygon points="7,11 7,12 6,12 6,10 10,10 10,13 9,13 9,12 8,12 8,11" fill="hsl(188, 39%, 58%)"/><rect x="6" y="10" width="4" height="1" fill="hsl(180,0%,0%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[7]))) {
            _mString = '<polygon points="7,11 7,12 6,12 6,10 10,10 10,12 9,12 9,11" fill="hsl(180, 100%, 100%)"/><rect x="5" y="10" width="6" height="1" fill="hsl(180,0%,0%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[8]))) {
            _mString = '<rect x="5" y="10" width="6" height="1" fill="hsl(180,0%,0%)"/><rect x="6" y="10" width="4" height="1" fill="hsl(180,100%,100%)"/> ';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[9]))) {
            _mString = '<rect x="5" y="10" width="6" height="1" fill="hsl(180,0%,0%)"/><rect x="6" y="10" width="4" height="1" fill="hsl(180,100%,100%)"/><rect x="7" y="10" width="1" height="1" fill="hsl(180,0%,0%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[10]))) {
            _mString = '<polygon points="6,12 6,11 5,11 5,10 6,10 6,11 10,11 10,12" fill="hsl(180,0%,0%)"/><rect x="9" y="11" width="2" height="1" fill="hsl(180,100%,100%)"/><rect x="11" y="11" width="1" height="1" fill="hsl(358, 100%, 51%)"/><polygon points="13,11 12,11 12,10 13,10 13,7 12,7 12,8 13,8 13,9 14,9 14,10 13,10 " fill="hsl(0, 0%, 90%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[11]))) {
            _mString = '<polygon points="9,10 11,10 11,14 10,14 10,13 9,13" fill="hsl(119, 100%, 41%)"/><rect x="5" y="10" width="6" height="1" fill="hsl(180,0%,0%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[12]))) {
            _mString = '<polygon points="7,11 7,12 6,12 6,10 9,10 11,10 11,14 10,14 10,13 9,13 9,11" fill="hsl(352, 100%, 41%)"/><rect x="5" y="10" width="6" height="1" fill="hsl(180,0%,0%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[13]))) {
            _mString = '<polygon points="5,10 11,10 11,11 10,11 10,13 9,13 9,14 8,14 7,14 7,13 6,13 6,11 5,11," fill="hsl(180, 0%, 0%)"/><rect x="7" y="11" width="2" height="2" fill="hsl(4, 74%, 50%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[14]))) {
            _mString = '<polygon points=" 7,10 6,10 6,9 10,9 10,10 11,10 11,12 10,12 10,13 6,13 6,12 5,12 5,10" fill="hsl(180, 0%, 0%)"/><rect x="6" y="10" width="4" height="2" fill="hsl(4, 74%, 50%)"/><rect x="9" y="10" width="1" height="1" fill="hsl(180, 100%, 100%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[15]))) {
             _mString = '<rect x="7" y="10" width="2" height="2" fill="hsl(4, 74%, 50%)"/><rect x="8" y="10" width="1" height="1" fill="hsl(180, 100%, 100%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[16]))) {
            _mString = '<polygon points="6,10 11,10 11,9 10,9 10,12 11,12 11,11 6,11" fill="hsl(180, 0%, 0%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[17]))) {
            _mString = '<polygon points="3,8 4,8 4,9 5,9 5,10 6,10 6,9 10,9 10,10 11,10 11,9 12,9 12,8 13,8 13,9 12,9 12,10 11,10 11,12 13,12 13,13 3,13 3,12 5,12 5,10 4,10 4,9 3,9 " fill="hsl(0, 0%, 20%)"/><rect x="6" y="10" width="4" height="2" fill="hsl(53, 12%, 85%)"/>';
        }
        return(_mString,_mJson = _trait);
    }
}