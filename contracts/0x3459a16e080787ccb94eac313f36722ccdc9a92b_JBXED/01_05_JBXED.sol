// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Juice Bruns | Editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////
//                                                                   //
//                                                                   //
//       __  _  _  __  ___  ____    ____  ____  _  _  __ _  ____     //
//     _(  )/ )( \(  )/ __)(  __)  (  _ \(  _ \/ )( \(  ( \/ ___)    //
//    / \) \) \/ ( )(( (__  ) _)    ) _ ( )   /) \/ (/    /\___ \    //
//    \____/\____/(__)\___)(____)  (____/(__\_)\____/\_)__)(____/    //
//                                                                   //
//                                                                   //
///////////////////////////////////////////////////////////////////////


contract JBXED is ERC721Creator {
    constructor() ERC721Creator("Juice Bruns | Editions", "JBXED") {}
}