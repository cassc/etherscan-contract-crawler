// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ediep editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//        E        //
//        D        //
//    E D I E P    //
//        T        //
//        I        //
//        O        //
//        N        //
//        S        //
//                 //
//                 //
/////////////////////


contract EEE is ERC721Creator {
    constructor() ERC721Creator("ediep editions", "EEE") {}
}