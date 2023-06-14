pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";

// Extracts Quidd data from a standard Quidd Token ID
/*
 * The standard Quidd Mintable token ID is a uint256 encoded with several bits of unique print data.
 * From leftmost bit to right:
 * Bits 1-16:    Publisher ID (supports up to 65,535 publishers)
 * Bits 17-32:   Channel ID (supports up to 65,535 channels)
 * Bits 33-64:   Set ID
 * Bits 64-96:   Quidd ID
 * Bits 97-98:   Item (Set) type: 0 = Standard, 1 = Award, 2 = Collector's Edition
 * Bits 99-100:  Product type: 1 = Sticker, 2 = Card, 3 = 3D Figure
 * Bits 101-128: Shiny ID, or all 0's if not a shiny (28 bits, supports up to 268,435,456, way more than enough)
 * Bits 129-136: Edition (8 bits, supports up to 255 editions)
 * Bits 137-160: Print Number (24 bits, supports up to number 16,777,215)
 * Bits 161-192: Token Version (32 bits starting at 0, but probably only the rightmost bits will be used)
 * Bits 193-256: Print ID (uint64)
 */
library QuiddTokenIDv0 {
  function publisherId(uint256 self) internal pure returns (uint16) {
    return uint16(self >> 240);
  }  

  function channelId(uint256 self) internal pure returns (uint16) {
    return uint16(self >> 224);
  }  

  function setId(uint256 self) internal pure returns (uint32) {
    return uint32(self >> 192);
  }  

  function quiddId(uint256 self) internal pure returns (uint32) {
    return uint32(self >> 160);

  }  

  function itemType(uint256 self) internal pure returns (uint8) {
    uint256 shifty = self;
    shifty = shifty << 96;
    shifty = shifty >> 254;
    return uint8(shifty);
  }

  function productType(uint256 self) internal pure returns (uint8) {
    uint256 shifty = self;
    shifty = shifty << 98;
    shifty = shifty >> 254;
    return uint8(shifty);
  }

  function shinyId(uint256 self) internal pure returns (uint32) {
    uint256 shifty = self;
    shifty = shifty << 100;
    shifty = shifty >> 228;
    return uint32(shifty);
  }

  function edition(uint256 self) internal pure returns (uint8) {
    return uint8(self >> 120);
  }

  function printNumber(uint256 self) internal pure returns (uint24) {
    return uint24(self >> 96);
  }

  function tokenVersion(uint256 self) internal pure returns (uint32) {
    return uint32(self >> 64);
  }

  function printId(uint256 self) internal pure returns (uint64) {
    return uint64(self);
  }

  /*
  function uintToByteStr(uint256 self) internal pure returns (string memory) {
    uint256 shifty = self;
    string memory str;
    for (uint i = 0; i < 32; i++) {
      uint r = shifty % 256;
      shifty = shifty / 256;
      str = string(bytes.concat("[", bytes(Strings.toString(r)), "] ", bytes(str)));
    }
    return str;
  }
  */
}


contract TestQuiddTokenIDv0 {
  using QuiddTokenIDv0 for uint256;
  
  function getPublisherId(uint256 tid) public pure returns (uint16) {
    return tid.publisherId();
  }  
  
  function getChannelId(uint256 tid) public pure returns (uint16) {
    return tid.channelId();
  }  
  
  function getSetId(uint256 tid) public pure returns (uint32) {
    return tid.setId();
  }  
  
  function getQuiddId(uint256 tid) public pure returns (uint32) {
    return tid.quiddId();
  }  
  
  function getItemType(uint256 tid) public pure returns (uint8) {
    return tid.itemType();
  }  
  
  function getProductType(uint256 tid) public pure returns (uint8) {
    return tid.productType();
  }  
  
  function getShinyId(uint256 tid) public pure returns (uint32) {
    return tid.shinyId();
  }  
  
  function getEdition(uint256 tid) public pure returns (uint8) {
    return tid.edition();
  }  
  
  function getPrintNumber(uint256 tid) public pure returns (uint24) {
    return tid.printNumber();
  }  
  
  function getTokenVersion(uint256 tid) public pure returns (uint32) {
    return tid.tokenVersion();
  }  
  
  function getPrintId(uint256 tid) public pure returns (uint64) {
    return tid.printId();
  }  
}