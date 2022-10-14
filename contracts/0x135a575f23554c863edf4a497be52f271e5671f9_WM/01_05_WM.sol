// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WARM
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//                            //
//     _,_ _,_ __, _,  __,    //
//     | / | / |_  |   |_     //
//     |/  |/  |   | , |      //
//     ~   ~   ~~~ ~~~ ~      //
//                            //
//                            //
//                            //
//                            //
////////////////////////////////


contract WM is ERC721Creator {
    constructor() ERC721Creator("WARM", "WM") {}
}