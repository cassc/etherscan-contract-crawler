// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: In The Sky
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                __/\__                //
//               `==/\==`               //
//     ____________/__\____________     //
//    /____________________________\    //
//      __||__||__/.--.\__||__||__      //
//     /__|___|___( >< )___|___|__\     //
//               _/`--`\_               //
//    ITS       (/------\)              //
//                                      //
//                                      //
//////////////////////////////////////////


contract ITS is ERC721Creator {
    constructor() ERC721Creator("In The Sky", "ITS") {}
}