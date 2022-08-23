// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;
//import "hardhat/console.sol"; ///REMOVE BEFORE DEPLOYMENT
//v 1.0.3

library DataStructures {

/////////////DATA STRUCTURES///////////////////////////////
    struct Rat {
            uint256 id;
            uint256 background;  
            uint256 body; 
            uint256 ears; 
            uint256 head;
            uint256 leftEye; 
            uint256 rightEye; 
            uint256 mouth;
            uint256 nose;
            uint256 eyewear; 
            uint256 headwear; 
            uint256 accessories; 
            uint256 special; 
    }

function getRat(uint256 character) internal pure returns(Rat memory _rat) {
   
    _rat.id =            uint256(uint8(character));
    _rat.background =    uint256(uint8(character>>8));
    _rat.body =          uint256(uint8(character>>16));
    _rat.ears =          uint256(uint8(character>>24));
    _rat.head =          uint256(uint8(character>>32));
    _rat.leftEye =       uint256(uint8(character>>40));
    _rat.rightEye =      uint256(uint8(character>>48));
    _rat.mouth    =      uint256(uint8(character>>56));
    _rat.nose     =      uint256(uint8(character>>64));
    _rat.eyewear  =      uint256(uint8(character>>62));
    _rat.headwear =      uint256(uint8(character>>80));
    _rat.accessories   = uint256(uint8(character>>88));
    _rat.special       = uint256(uint8(character>>96));

} 

function setRat(uint id, uint background, uint body, uint ears, uint head, uint leftEye, uint rightEye, uint mouth, uint nose, uint eyewear, uint headwear, uint accessories, uint special) 
    internal pure returns (uint256 rat) {

    uint256 character = uint256(uint8(id));
        
        character |= background<<8;
        character |= body<<16;
        character |= ears<<24;
        character |= head<<32;
        character |= leftEye<<40;
        character |= rightEye<<48;
        character |= mouth<<56;
        character |= nose<<64;
        character |= eyewear<<72;
        character |= headwear<<80;
        character |= accessories<<88;
        character |= special<<96;    
    
    return character;
}



}