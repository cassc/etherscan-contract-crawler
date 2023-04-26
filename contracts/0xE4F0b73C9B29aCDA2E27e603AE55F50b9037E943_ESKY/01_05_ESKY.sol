// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Twitter token for eskylabs
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//                _          _       _             //
//               | |        | |     | |            //
//       ___  ___| | ___   _| | __ _| |__  ___     //
//      / _ \/ __| |/ / | | | |/ _` | '_ \/ __|    //
//     |  __/\__ \   <| |_| | | (_| | |_) \__ \    //
//      \___||___/_|\_\\__, |_|\__,_|_.__/|___/    //
//                      __/ |                      //
//                     |___/                       //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract ESKY is ERC1155Creator {
    constructor() ERC1155Creator("Twitter token for eskylabs", "ESKY") {}
}