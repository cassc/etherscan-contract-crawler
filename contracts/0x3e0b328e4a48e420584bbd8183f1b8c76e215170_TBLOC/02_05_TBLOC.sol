// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Title Block
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////
//                                                                        //
//                                                                        //
//    ───────────────────────────────────────────────────────────────     //
//    ───────────────────────────────────────────────────────────────     //
//    ─▀▀█▀▀─▀█▀─▀▀█▀▀─░█────░█▀▀▀────░█▀▀█─░█────░█▀▀▀█─░█▀▀█─░█─▄▀─     //
//    ──░█───░█───░█───░█────░█▀▀▀────░█▀▀▄─░█────░█──░█─░█────░█▀▄──     //
//    ──░█───▄█▄──░█───░█▄▄█─░█▄▄▄────░█▄▄█─░█▄▄█─░█▄▄▄█─░█▄▄█─░█─░█─     //
//    ───────────────────────────────────────────────────────────────     //
//    ───────────────────────────────────────────────────────────────     //
//                                                                        //
//                                                                        //
////////////////////////////////////////////////////////////////////////////


contract TBLOC is ERC721Creator {
    constructor() ERC721Creator("Title Block", "TBLOC") {}
}