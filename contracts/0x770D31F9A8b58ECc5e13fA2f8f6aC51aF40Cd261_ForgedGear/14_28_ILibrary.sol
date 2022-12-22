// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ILibrary {
  struct CardImageInput {
    string name;
    string prefix;
    string suffix;
    string itemGraphic;
    string prefixGraphic;
    string suffixGraphic;
    string r0n1Graphic;
    bool isForged;
    bool hasR0N1;
    string cardGraphic;
    string font;
  }

  struct ImageInput {
    string itemGraphic;
    string prefixGraphic;
    string r0n1Graphic;
    bool isForged;
    bool hasR0N1;
  }
}