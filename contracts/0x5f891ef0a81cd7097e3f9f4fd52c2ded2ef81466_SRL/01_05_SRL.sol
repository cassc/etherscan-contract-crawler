// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: soroyal
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////
//                                                                   //
//                                                                   //
//                                                                   //
//                                                                   //
//     __                       _                       _            //
//    / _| _  _  _ __   _  ||  / \ _ ()_ ()  _  _  ||  / \  _ ||     //
//    \_ \/o\/_|/o\\ V7/o\ || ( o )_||/o\|||/ \/o\ || | o |/_|| ]    //
//    |__/\_/L| \_/ )/ \_,]L|  \_/L| L\_/L|L_n|\_,]L| |_n_|L| L|     //
//                 //                  _)                            //
//                                                                   //
//                                                                   //
//                                                                   //
///////////////////////////////////////////////////////////////////////


contract SRL is ERC721Creator {
    constructor() ERC721Creator("soroyal", "SRL") {}
}