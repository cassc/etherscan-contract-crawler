// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: From Fire To Darkness
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//                                   //
//     (     (            (          //
//     )\ )  )\ )   *   ) )\ )       //
//    (()/( (()/( ` )  /((()/(       //
//     /(_)) /(_)) ( )(_))/(_))      //
//    (_))_|(_))_|(_(_())(_))_       //
//    | |_  | |_  |_   _| |   \      //
//    | __| | __|   | |   | |) |     //
//    |_|   |_|     |_|   |___/      //
//                                   //
//                                   //
//                                   //
//                                   //
///////////////////////////////////////


contract FFTD is ERC1155Creator {
    constructor() ERC1155Creator("From Fire To Darkness", "FFTD") {}
}