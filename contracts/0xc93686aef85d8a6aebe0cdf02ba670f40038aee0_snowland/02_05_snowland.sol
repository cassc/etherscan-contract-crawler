// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: snowland
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//                                                     //
//                            _                 _      //
//     ___ _ __   _____      _| | __ _ _ __   __| |    //
//    / __| '_ \ / _ \ \ /\ / / |/ _` | '_ \ / _` |    //
//    \__ \ | | | (_) \ V  V /| | (_| | | | | (_| |    //
//    |___/_| |_|\___/ \_/\_/ |_|\__,_|_| |_|\__,_|    //
//                                                     //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract snowland is ERC721Creator {
    constructor() ERC721Creator("snowland", "snowland") {}
}