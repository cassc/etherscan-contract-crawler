// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IGRDS {

    struct GroupingExpanded {
      string[] hexColors;
      string[] symbols;
      uint[2][] cidsUnique;
      uint[2][] sidsUnique;
      uint tokenID;
      bool isGrid;
      uint gridValue;
      string gridName;
      uint gridDimension;
      string[] filledColors; 
      string[] filledSymbols;
      uint rectHeight;
      uint circleRadius; 
      bool animationIdle;
      bool special;
      string specialCode;
      string _sPatterns;
      uint8 allSameSwitch;
    }

    struct NameCount {
      string name;
      uint count;
    }

}