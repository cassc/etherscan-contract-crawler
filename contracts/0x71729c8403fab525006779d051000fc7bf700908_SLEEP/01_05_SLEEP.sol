// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A/SLEEP COLLECTION
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//       db       dP .dP"Y8 88     888888 888888 88""Yb     //
//      dPYb     dP  `Ybo." 88     88__   88__   88__dP     //
//     dP__Yb   dP   o.`Y8b 88  .o 88""   88""   88"""      //
//    dP""""Yb dP    8bodP' 88ood8 888888 888888 88         //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract SLEEP is ERC721Creator {
    constructor() ERC721Creator("A/SLEEP COLLECTION", "SLEEP") {}
}