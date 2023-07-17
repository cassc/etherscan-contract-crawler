// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: seansalexa editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//     ____  ____   __   __ _  ____   __   __    ____  _  _   __      //
//    / ___)(  __) / _\ (  ( \/ ___) / _\ (  )  (  __)( \/ ) / _\     //
//    \___ \ ) _) /    \/    /\___ \/    \/ (_/\ ) _)  )  ( /    \    //
//    (____/(____)\_/\_/\_)__)(____/\_/\_/\____/(____)(_/\_)\_/\_/    //
//    Creator Alexandra Makarenko(seansalexa)                         //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract SAED is ERC1155Creator {
    constructor() ERC1155Creator("seansalexa editions", "SAED") {}
}