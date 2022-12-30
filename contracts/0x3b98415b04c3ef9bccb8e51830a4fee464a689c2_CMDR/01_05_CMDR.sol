// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Commodore
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//    888888 88  88 888888      dP""b8  dP"Yb  8b    d8 8b    d8 8b    d8  dP"Yb  8888b.   dP"Yb  88""Yb 888888     //
//      88   88  88 88__       dP   `" dP   Yb 88b  d88 88b  d88 88b  d88 dP   Yb  8I  Yb dP   Yb 88__dP 88__       //
//      88   888888 88""       Yb      Yb   dP 88YbdP88 88YbdP88 88YbdP88 Yb   dP  8I  dY Yb   dP 88"Yb  88""       //
//      88   88  88 888888      YboodP  YbodP  88 YY 88 88 YY 88 88 YY 88  YbodP  8888Y"   YbodP  88  Yb 888888     //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CMDR is ERC1155Creator {
    constructor() ERC1155Creator("The Commodore", "CMDR") {}
}