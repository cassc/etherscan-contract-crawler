// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Constellation
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                    //
//                                                                                                    //
//     dP""b8  dP"Yb  88b 88 .dP"Y8 888888 888888 88     88        db    888888 88  dP"Yb  88b 88     //
//    dP   `" dP   Yb 88Yb88 `Ybo."   88   88__   88     88       dPYb     88   88 dP   Yb 88Yb88     //
//    Yb      Yb   dP 88 Y88 o.`Y8b   88   88""   88  .o 88  .o  dP__Yb    88   88 Yb   dP 88 Y88     //
//     YboodP  YbodP  88  Y8 8bodP'   88   888888 88ood8 88ood8 dP""""Yb   88   88  YbodP  88  Y8     //
//                                                                                                    //
//                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CN is ERC721Creator {
    constructor() ERC721Creator("Constellation", "CN") {}
}