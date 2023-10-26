// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kipheo Starfire
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                                                      //
//         __+     __ __ +                              //
//    |_/||__)|__||_ /  \                               //
//    | \||+  |  ||__\__/                               //
//     _____+    __  __  __  __ +                       //
//    (_  |  /\ |__)|_ ||__)|_  .   .                   //
//    __) | /--\| \ |  || \ |__   .   +                 //
//                                                      //
//        .  + Starfire Designs // Art by Kipheo   +    //
//                  .  * Digital Painted Works *        //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract KIPHEO is ERC721Creator {
    constructor() ERC721Creator("Kipheo Starfire", "KIPHEO") {}
}