// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Creators {
    address internal constant creator1 = 0xD1535726A1e934e69D49166e8e55ee30A3A805dC;
    address internal constant creator2 = 0x66e1fB14692dCF1Dc6ca0Ffe15d26ac8820485a6;
    address internal constant creator3 = 0x50fedF54Da0789f28E11b4c9f4739e333154eE53;
    address internal constant creator4 = 0x3f0b60c5f0e6c7a98414c4D68C17022c37B58856;
    address internal constant creator5 = 0xAFFee832705270a73CDC21FE907a1D08d750Ff7E;
    address internal constant creator6 = 0x5EDc650E6854Abc04229F2B7A91FeF54c2841652;
    address internal constant creator7 = 0x29D632C1186c40915b7Bbcdf31f9FF0C0dBEF167;
    address internal constant creator8 = 0x36974DA3EaF180Ceec2D0463947190fE4f19EE42;
    address internal constant creator9 = 0x3C9579CbA494c27a46d5E6Cb527F548DDA658815;
    address internal constant creator10 = 0x7f321b53316553a2250E0C7B2711A7d86dc449Ac;
    
    function isCreator(address operator) public pure virtual returns (bool) {
        return operator == creator1 ||
            operator == creator2 ||
            operator == creator3 ||
            operator == creator4 ||
            operator == creator5 ||
            operator == creator6 ||
            operator == creator7 ||
            operator == creator8 ||
            operator == creator9 ||
            operator == creator10;
    }
}