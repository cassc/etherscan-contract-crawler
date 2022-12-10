// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KROMATIK
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//       ____ ___   _______  _______   ________  ____ ___     //
//      ╱    ╱   ╲╱╱       ╲╱       ╲╲╱        ╲╱    ╱   ╲    //
//     ╱         ╱╱        ╱        ╱╱        _╱         ╱    //
//    ╱╱       _╱        _╱         ╱╱       ╱╱╱       _╱     //
//    ╲╲___╱___╱╲____╱___╱╲__╱__╱__╱ ╲_____╱╱ ╲╲___╱___╱      //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract KRMTK is ERC721Creator {
    constructor() ERC721Creator("KROMATIK", "KRMTK") {}
}