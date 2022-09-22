// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./lib/openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./lib/openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./lib/openzeppelin/contracts/token/ERC1155/IERC1155.sol";


//Hero data structure
struct HeroMetaData {
    bool opened;        //box or hero
    uint8 gen;          //generation

    uint64 summon_cd;       //next summon time
    uint8 summon_cnt;       //current summon count
    uint8 maxsummon_cnt;    //max summon count
    uint8 d;      //Dominant gene
    uint8 r1;     //Recessive gene 1
    uint8 r2;     //Recessive gene 2
    uint8 r3;     //Recessive gene 3
    uint32 p1;    //parent 1
    uint32 p2;    //parent 2
}


interface IHero721 is IERC721, IERC721Enumerable {
    function getMeta(uint32 token_id) external view returns (HeroMetaData memory);
    function setMeta(uint32 token_id, HeroMetaData calldata meta) external;
    function burn(uint32 token_id) external;
    function exists(uint32 token_id) external view returns (bool);
    function createCreationTo(address to, HeroMetaData calldata meta) external;
    function createDescendantsTo(address to, HeroMetaData calldata meta) external;
    function calcCreationLimit() external view returns (uint16);
}

interface IClothing721 {
    function manageMintTo(address to, uint32 clothes_id) external;
}

interface IHeroManage {
    function summonLease(address account, uint32 token_id1, uint32 token_id2) external;
}