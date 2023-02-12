// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Petals
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                         //
//                                                                                         //
//                                                                                         //
//                                        ,,                                               //
//    `7MM"""Mq.          mm            `7MM                                               //
//      MM   `MM.         MM              MM                                               //
//      MM   ,M9 .gP"Ya mmMMmm  ,6"Yb.    MM  ,pP"Ybd                                      //
//      MMmmdM9 ,M'   Yb  MM   8)   MM    MM  8I   `"                                      //
//      MM      8M""""""  MM    ,pm9MM    MM  `YMMMa.                                      //
//      MM      YM.    ,  MM   8M   MM    MM  L.   I8                                      //
//    .JMML.     `Mbmmd'  `Mbmo`Moo9^Yo..JMML.M9mmmP'                                      //
//                                                                                         //
//     __                       __  ___                                                    //
//    |__) \ /    |__| \_/ |\ |  / |__                                                     //
//    |__)  |     |  | / \ | \| /_ |___ ___                                                //
//                                                                                         //
//                                                                                         //
//                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////


contract PETAL is ERC721Creator {
    constructor() ERC721Creator("Petals", "PETAL") {}
}