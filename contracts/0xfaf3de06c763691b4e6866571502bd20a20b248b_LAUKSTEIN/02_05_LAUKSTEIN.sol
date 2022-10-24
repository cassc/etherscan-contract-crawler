// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Binyamin Laukstein
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//    88        db    88   88 88  dP .dP"Y8 888888 888888 88 88b 88    //
//    88       dPYb   88   88 88odP  `Ybo."   88   88__   88 88Yb88    //
//    88  .o  dP__Yb  Y8   8P 88"Yb  o.`Y8b   88   88""   88 88 Y88    //
//    88ood8 dP""""Yb `YbodP' 88  Yb 8bodP'   88   888888 88 88  Y8    //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


contract LAUKSTEIN is ERC721Creator {
    constructor() ERC721Creator("Binyamin Laukstein", "LAUKSTEIN") {}
}