// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface PottedTypes {
    struct Gene {
        uint dna;
        uint revealNum;
        bool isReroll;
    }

    struct MyPotted {
      Potted potted;
      Branch branch;
      Blossom blossom;
      Bg bg;
    }

    struct Potted {
      string traitName;
      uint width;
      uint height;
      uint x;
      uint y;
      uint id;
    }

    struct Branch {
      string traitName;
      uint width;
      uint height;
      uint unique;
      uint x;
      uint y;
      uint[] pointX;
      uint[] pointY;
      uint id;
    }

    // Each blossom max count <= branchPointX.length
    struct Blossom {
      string traitName;
      uint[] width;
      uint[] height;
      uint[] childs;
      uint id;
    }

    struct Bg {
      string traitName;
      uint id;
    }
}