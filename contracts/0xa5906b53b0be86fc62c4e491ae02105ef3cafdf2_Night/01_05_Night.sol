// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Indiigo Arts Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//                                                                    //
//                                                                    //
//      __  __ _  ____  __  __  ___   __    __   ____  ____  ____     //
//     (  )(  ( \(    \(  )(  )/ __) /  \  / _\ (  _ \(_  _)/ ___)    //
//      )( /    / ) D ( )(  )(( (_ \(  O )/    \ )   /  )(  \___ \    //
//     (__)\_)__)(____/(__)(__)\___/ \__/ \_/\_/(__\_) (__) (____/    //
//                                                                    //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract Night is ERC1155Creator {
    constructor() ERC1155Creator("Indiigo Arts Editions", "Night") {}
}