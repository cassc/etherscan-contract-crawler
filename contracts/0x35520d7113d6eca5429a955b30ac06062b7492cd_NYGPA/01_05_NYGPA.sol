// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NotYourGrandPopArt
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    ,-,-.   .  . ,---. .-,--.   ,.       //
//    ` | |   |  | |  -'  '|__/  / |       //
//      | |-. |  | |  ,-' .|    /~~|-.     //
//     ,' `-' `--| `---|  `'  ,'   `-'     //
//            .- |  ,-.|                   //
//            `--'  `-+'                   //
//                                         //
//                                         //
/////////////////////////////////////////////


contract NYGPA is ERC721Creator {
    constructor() ERC721Creator("NotYourGrandPopArt", "NYGPA") {}
}