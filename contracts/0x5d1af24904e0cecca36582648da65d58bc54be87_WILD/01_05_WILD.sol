// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WILD by Aimee Del Valle
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    WW      WW IIIII LL      DDDDD       //
//    WW      WW  III  LL      DD  DD      //
//    WW   W  WW  III  LL      DD   DD     //
//     WW WWW WW  III  LL      DD   DD     //
//      WW   WW  IIIII LLLLLLL DDDDDD      //
//                                         //
//                                         //
/////////////////////////////////////////////


contract WILD is ERC721Creator {
    constructor() ERC721Creator("WILD by Aimee Del Valle", "WILD") {}
}