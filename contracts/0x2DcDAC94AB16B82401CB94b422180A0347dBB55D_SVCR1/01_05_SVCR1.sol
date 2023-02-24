// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Scavengers Crate
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                       //
//                                                                                                                                                       //
//                                                                                                                                                       //
//                                                                                                                                                       //
//                                                                                                                       ,,    ,,                        //
//     .M"""bgd                                                                                    `7MMF'   `7MF'      `7MM  `7MM                        //
//    ,MI    "Y                                                                                      `MA     ,V          MM    MM                        //
//    `MMb.      ,p6"bo   ,6"Yb.`7M'   `MF'.gP"Ya `7MMpMMMb.  .P"Ybmmm .gP"Ya `7Mb,od8 ,pP"Ybd        VM:   ,V ,6"Yb.    MM    MM  .gP"Ya `7M'   `MF'    //
//      `YMMNq. 6M'  OO  8)   MM  VA   ,V ,M'   Yb  MM    MM :MI  I8  ,M'   Yb  MM' "' 8I   `"         MM.  M'8)   MM    MM    MM ,M'   Yb  VA   ,V      //
//    .     `MM 8M        ,pm9MM   VA ,V  8M""""""  MM    MM  WmmmP"  8M""""""  MM     `YMMMa.         `MM A'  ,pm9MM    MM    MM 8M""""""   VA ,V       //
//    Mb     dM YM.    , 8M   MM    VVV   YM.    ,  MM    MM 8M       YM.    ,  MM     L.   I8          :MM;  8M   MM    MM    MM YM.    ,    VVV        //
//    P"Ybmmd"   YMbmd'  `Moo9^Yo.   W     `Mbmmd'.JMML  JMML.YMMMMMb  `Mbmmd'.JMML.   M9mmmP'           VF   `Moo9^Yo..JMML..JMML.`Mbmmd'    ,V         //
//                                                           6'     dP                                                                       ,V          //
//                                                           Ybmmmd'                                                                      OOb"           //
//                                                                                                                                                       //
//                                                                                                                                                       //
//                                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SVCR1 is ERC721Creator {
    constructor() ERC721Creator("Scavengers Crate", "SVCR1") {}
}