// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;

library EldersDataStructures {

struct EldersMeta {
            uint256 strength;
            uint256 agility;
            uint256 intellegence;
            uint256 healthPoints;
            uint256 attackPoints; 
            uint256 mana;
            uint256 primaryWeapon; 
            uint256 secondaryWeapon; 
            uint256 armor; 
            uint256 level;
            uint256 head;                       
            uint256 body;  
            uint256 race;  
            uint256 elderClass;                                     
}

  
function getElder(uint256 _elder) internal pure returns(EldersMeta memory elder) {

    elder.strength =         uint256(uint16(_elder));
    elder.agility =          uint256(uint16(_elder>>16));
    elder.intellegence =     uint256(uint16(_elder>>32));
    elder.attackPoints =     uint256(uint16(_elder>>48));
    elder.healthPoints =     uint256(uint16(_elder>>64));
    elder.mana =             uint256(uint16(_elder>>80));
    elder.primaryWeapon =    uint256(uint16(_elder>>96));
    elder.secondaryWeapon =  uint256(uint16(_elder>>112));
    elder.armor =            uint256(uint16(_elder>>128));
    elder.level =            uint256(uint16(_elder>>144));
    elder.head =             uint256(uint16(_elder>>160));
    elder.body =             uint256(uint16(_elder>>176));
    elder.race =             uint256(uint16(_elder>>192));
    elder.elderClass =       uint256(uint16(_elder>>208));    

} 

function setElder(
                uint256 strength,
                uint256 agility,
                uint256 intellegence,                
                uint256 attackPoints,
                uint256 healthPoints, 
                uint256 mana,
                uint256 primaryWeapon, 
                uint256 secondaryWeapon,
                uint256 armor,
                uint256 level,
                uint256 head,
                uint256 body,
                uint256 race,
                uint256 elderClass )

    internal pure returns (uint256 character) {

    character = uint256(strength);
    
    character |= agility<<16;
    character |= intellegence<<32;
    character |= attackPoints<<48;
    character |= healthPoints<<64;
    character |= mana<<80;
    character |= primaryWeapon<<96;
    character |= secondaryWeapon<<112;
    character |= armor<<128;
    character |= level<<144;
    character |= head<<160;
    character |= body<<176;
    character |= race<<192;
    character |= elderClass<<208;
    
    return character;
}


}