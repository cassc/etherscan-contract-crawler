// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: the ONE - white edition by Marian Kretschmer
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////
//                                                                        //
//                                                                        //
//     ______  _             _     _  _                                   //
//    (____  \| |           | |   | |(_)                          _       //
//     ____)  ) | ___   ____| |  _| | _ ____  _____ _____  ____ _| |_     //
//    |  __  (| |/ _ \ / ___) |_/ ) || |  _ \| ___ (____ |/ ___|_   _)    //
//    | |__)  ) | |_| ( (___|  _ (| || | | | | ____/ ___ | |     | |_     //
//    |______/ \_)___/ \____)_| \_)\_)_|_| |_|_____)_____|_|      \__)    //
//                                                                        //
//                                                                        //
//                                                                        //
////////////////////////////////////////////////////////////////////////////


contract ONE is ERC721Creator {
    constructor() ERC721Creator("the ONE - white edition by Marian Kretschmer", "ONE") {}
}