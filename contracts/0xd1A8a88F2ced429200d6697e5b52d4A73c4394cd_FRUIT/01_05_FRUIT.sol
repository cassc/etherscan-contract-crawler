// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FRUIT MACHINE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//     (     (           (                //
//     )\ )  )\ )        )\ )  *   )      //
//    (()/( (()/(    (  (()/(` )  /(      //
//     /(_)) /(_))   )\  /(_))( )(_))     //
//    (_))_|(_))  _ ((_)(_)) (_(_())      //
//    | |_  | _ \| | | ||_ _||_   _|      //
//    | __| |   /| |_| | | |   | |        //
//    |_|   |_|_\ \___/ |___|  |_|        //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract FRUIT is ERC721Creator {
    constructor() ERC721Creator("FRUIT MACHINE", "FRUIT") {}
}