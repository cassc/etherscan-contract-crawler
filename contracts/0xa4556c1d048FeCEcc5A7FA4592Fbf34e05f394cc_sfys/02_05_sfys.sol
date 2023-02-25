// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SFYS surfing vibes
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//    .dP"Y8 888888    db    888888  dP"Yb  88""Yb Yb  dP  dP"Yb  88   88 88""Yb .dP"Y8 888888 88     888888        //
//    `Ybo." 88__     dPYb   88__   dP   Yb 88__dP  YbdP  dP   Yb 88   88 88__dP `Ybo." 88__   88     88__          //
//    o.`Y8b 88""    dP__Yb  88""   Yb   dP 88"Yb    8P   Yb   dP Y8   8P 88"Yb  o.`Y8b 88""   88  .o 88""          //
//    8bodP' 888888 dP""""Yb 88      YbodP  88  Yb  dP     YbodP  `YbodP' 88  Yb 8bodP' 888888 88ood8 88            //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract sfys is ERC721Creator {
    constructor() ERC721Creator("SFYS surfing vibes", "sfys") {}
}