// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Synthesis x Farbfeld
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//     dP"8 Y88b Y8P Y88b Y88   Y8b Y8P   888'Y88 888'Y88     //
//    C8b Y  Y88b Y   Y88b Y8    Y8b Y    888 ,'Y 888 ,'Y     //
//     Y8b    Y88b   b Y88b Y     Y8b     888C8   888C8       //
//    b Y8D    888   8b Y88b     e Y8b    888 "   888 "       //
//    8edP     888   88b Y88b   d8b Y8b   888     888         //
//                                                            //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract SXF is ERC721Creator {
    constructor() ERC721Creator("Synthesis x Farbfeld", "SXF") {}
}