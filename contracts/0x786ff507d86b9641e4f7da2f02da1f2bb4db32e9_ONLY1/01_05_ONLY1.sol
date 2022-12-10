// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Only One Collection  [Voice Journal]
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//     __      __   _                 _                              _     //
//     \ \    / /  (_)               | |                            | |    //
//      \ \  / /__  _  ___ ___       | | ___  _   _ _ __ _ __   __ _| |    //
//       \ \/ / _ \| |/ __/ _ \  _   | |/ _ \| | | | '__| '_ \ / _` | |    //
//        \  / (_) | | (_|  __/ | |__| | (_) | |_| | |  | | | | (_| | |    //
//         \/ \___/|_|\___\___|  \____/ \___/ \__,_|_|  |_| |_|\__,_|_|    //
//                                                                         //
//                                                                         //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract ONLY1 is ERC721Creator {
    constructor() ERC721Creator("Only One Collection  [Voice Journal]", "ONLY1") {}
}