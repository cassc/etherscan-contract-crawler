// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Gallery Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                       //
//                                                                                                                                       //
//    888888 88  88 888888    dP""b8    db    88     88     888888 88""Yb Yb  dP   888888 8888b.  88 888888 88  dP"Yb  88b 88 .dP"Y8     //
//      88   88  88 88__     dP   `"   dPYb   88     88     88__   88__dP  YbdP    88__    8I  Yb 88   88   88 dP   Yb 88Yb88 `Ybo."     //
//      88   888888 88""     Yb  "88  dP__Yb  88  .o 88  .o 88""   88"Yb    8P     88""    8I  dY 88   88   88 Yb   dP 88 Y88 o.`Y8b     //
//      88   88  88 888888    YboodP dP""""Yb 88ood8 88ood8 888888 88  Yb  dP      888888 8888Y"  88   88   88  YbodP  88  Y8 8bodP'     //
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AGGE is ERC1155Creator {
    constructor() ERC1155Creator("The Gallery Editions", "AGGE") {}
}