// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bridge DSGN x PAMILO CEIRONE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////
//                                                                                    //
//                                                                                    //
//     ____  ____  __  ____   ___  ____    ____  ____   ___  __ _                     //
//    (  _ \(  _ \(  )(    \ / __)(  __)  (    \/ ___) / __)(  ( \                    //
//     ) _ ( )   / )(  ) D (( (_ \ ) _)    ) D (\___ \( (_ \/    /                    //
//    (____/(__\_)(__)(____/ \___/(____)  (____/(____/ \___/\_)__)                    //
//                             _  _                                                   //
//                            ( \/ )                                                  //
//                             )  (                                                   //
//                            (_/\_)                                                  //
//     ____   __   _  _  __  __     __      ___  ____  __  ____   __   __ _  ____     //
//    (  _ \ / _\ ( \/ )(  )(  )   /  \    / __)(  __)(  )(  _ \ /  \ (  ( \(  __)    //
//     ) __//    \/ \/ \ )( / (_/\(  O )  ( (__  ) _)  )(  )   /(  O )/    / ) _)     //
//    (__)  \_/\_/\_)(_/(__)\____/ \__/    \___)(____)(__)(__\_) \__/ \_)__)(____)    //
//                                                                                    //
//                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////


contract BRDG is ERC1155Creator {
    constructor() ERC1155Creator("Bridge DSGN x PAMILO CEIRONE", "BRDG") {}
}