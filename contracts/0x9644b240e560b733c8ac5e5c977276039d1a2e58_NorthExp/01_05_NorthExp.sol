// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Northern Exposure
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//         __           _   _                          //
//      /\ \ \___  _ __| |_| |__   ___ _ __ _ __       //
//     /  \/ / _ \| '__| __| '_ \ / _ \ '__| '_ \      //
//    / /\  / (_) | |  | |_| | | |  __/ |  | | | |     //
//    \_\ \/ \___/|_|   \__|_| |_|\___|_|  |_| |_|     //
//                                                     //
//       __                                            //
//      /__\_  ___ __   ___  ___ _   _ _ __ ___        //
//     /_\ \ \/ / '_ \ / _ \/ __| | | | '__/ _ \       //
//    //__  >  <| |_) | (_) \__ \ |_| | | |  __/       //
//    \__/ /_/\_\ .__/ \___/|___/\__,_|_|  \___|       //
//              |_|                                    //
//                                                     //
//    intrepidphotos - Robert Downie Photography       //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract NorthExp is ERC721Creator {
    constructor() ERC721Creator("Northern Exposure", "NorthExp") {}
}