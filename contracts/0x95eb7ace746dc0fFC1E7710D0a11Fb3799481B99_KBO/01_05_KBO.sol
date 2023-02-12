// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Orange Sky
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                                                      //
//     _                           _                    //
//    | | ___ __ _ __ _____      _| |__   __ _ _ __     //
//    | |/ / '__| '__/ _ \ \ /\ / / '_ \ / _` | '__|    //
//    |   <| |  | | | (_) \ V  V /| |_) | (_| | |       //
//    |_|\_\_|  |_|  \___/ \_/\_/ |_.__/ \__,_|_|       //
//                                                      //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract KBO is ERC721Creator {
    constructor() ERC721Creator("Orange Sky", "KBO") {}
}