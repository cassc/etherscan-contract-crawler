// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AeltyArt
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//    ______          ___    __                     //
//    /\  _  \        /\_ \  /\ \__                 //
//    \ \ \L\ \     __\//\ \ \ \ ,_\  __  __        //
//     \ \  __ \  /'__`\\ \ \ \ \ \/ /\ \/\ \       //
//      \ \ \/\ \/\  __/ \_\ \_\ \ \_\ \ \_\ \      //
//       \ \_\ \_\ \____\/\____\\ \__\\/`____ \     //
//        \/_/\/_/\/____/\/____/ \/__/ `/___/> \    //
//                                        /\___/    //
//                                        \/__/     //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract aelty is ERC721Creator {
    constructor() ERC721Creator("AeltyArt", "aelty") {}
}