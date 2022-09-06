// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RFDZ
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//                             //
//             _______         //
//            |.-----.|        //
//            ||x . x||        //
//            ||_.-._||        //
//            `--)-(--`        //
//           __[=== o]___      //
//          |:::::::::::|\     //
//    jpgs  `-=========-`()    //
//                             //
//                             //
/////////////////////////////////


contract RFDZ is ERC721Creator {
    constructor() ERC721Creator("RFDZ", "RFDZ") {}
}