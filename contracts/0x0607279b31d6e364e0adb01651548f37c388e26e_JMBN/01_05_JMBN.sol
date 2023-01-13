// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JOURNEY MOMENTS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//       ####  ##   ##  ### ##   ###  ##      //
//        ##    ## ##    ##  ##    ## ##      //
//        ##   # ### #   ##  ##   # ## #      //
//        ##   ## # ##   ## ##    ## ##       //
//    ##  ##   ##   ##   ##  ##   ##  ##      //
//    ##  ##   ##   ##   ##  ##   ##  ##      //
//     ## #    ##   ##  ### ##   ###  ##      //
//                                            //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract JMBN is ERC721Creator {
    constructor() ERC721Creator("JOURNEY MOMENTS", "JMBN") {}
}