// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: nana* original cnp fan arts
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//                                         //
//    ,--,--,  ,--,--.,--,--,  ,--,--.     //
//    |      \' ,-.  ||      \' ,-.  |     //
//    |  ||  |\ '-'  ||  ||  |\ '-'  |     //
//    `--''--' `--`--'`--''--' `--`--'     //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract NANAarts is ERC1155Creator {
    constructor() ERC1155Creator("nana* original cnp fan arts", "NANAarts") {}
}