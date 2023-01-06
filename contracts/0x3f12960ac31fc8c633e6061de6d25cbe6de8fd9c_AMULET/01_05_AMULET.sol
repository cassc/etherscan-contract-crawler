// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Amulets
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//                                                                          //
//                                                                          //
//       db    8b    d8 88   88 88     888888 888888 .dP"Y8                 //
//      dPYb   88b  d88 88   88 88     88__     88   `Ybo."                 //
//     dP__Yb  88YbdP88 Y8   8P 88  .o 88""     88   o.`Y8b                 //
//    dP""""Yb 88 YY 88 `YbodP' 88ood8 888888   88   8bodP'                 //
//    <>AMULETS ARE A CONTRACT FOR SPIRITUAL ENRICHMENT AND PROTECTION<>    //
//                                                                          //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////


contract AMULET is ERC1155Creator {
    constructor() ERC1155Creator("Amulets", "AMULET") {}
}