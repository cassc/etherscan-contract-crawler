// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pepe
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//    __________                          //
//    \______   \ ____ ______   ____      //
//     |     ___// __ \\____ \_/ __ \     //
//     |    |   \  ___/|  |_> >  ___/     //
//     |____|    \___  >   __/ \___  >    //
//                   \/|__|        \/     //
//                                        //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract PEPE is ERC1155Creator {
    constructor() ERC1155Creator("Pepe", "PEPE") {}
}