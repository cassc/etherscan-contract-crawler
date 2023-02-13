// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MOON & BACK by PHRAZE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//                          //
//    ._ _  _  _ ._         //
//    [ | )(_)(_)[ )        //
//                          //
//            .             //
//     _.._  _|             //
//    (_][ )(_]             //
//                          //
//    .        .            //
//    |_  _. _.;_/          //
//    [_)(_](_.| \          //
//                          //
//    .                     //
//    |_   .                //
//    [_)\_|                //
//       ._|                //
//       .                  //
//    ._ |_ ._. _.__. _     //
//    [_)[ )[  (_] /_(/,    //
//    |                     //
//                          //
//                          //
//////////////////////////////


contract MOON is ERC721Creator {
    constructor() ERC721Creator("MOON & BACK by PHRAZE", "MOON") {}
}