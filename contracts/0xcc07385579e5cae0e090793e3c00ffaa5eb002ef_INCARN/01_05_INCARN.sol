// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ЛЖА
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//     (o\-(o\        //
//     (      \       //
//     a  a    ;      //
//     (O _   /_      //
//    ,'\-j_.'  `.    //
//                    //
//                    //
////////////////////////


contract INCARN is ERC721Creator {
    constructor() ERC721Creator(unicode"ЛЖА", "INCARN") {}
}