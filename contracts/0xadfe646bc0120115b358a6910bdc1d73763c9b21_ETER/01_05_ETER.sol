// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Eternity
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                   //
//                                                                                                   //
//     ooooooooooo ooooooooooo ooooooooooo oooooooooo  oooo   oooo ooooo ooooooooooo ooooo  oooo     //
//      888    88  88  888  88  888    88   888    888  8888o  88   888  88  888  88   888  88       //
//      888ooo8        888      888ooo8     888oooo88   88 888o88   888      888         888         //
//      888    oo      888      888    oo   888  88o    88   8888   888      888         888         //
//     o888ooo8888    o888o    o888ooo8888 o888o  88o8 o88o    88  o888o    o888o       o888o        //
//                                                                                                   //
//                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////


contract ETER is ERC721Creator {
    constructor() ERC721Creator("Eternity", "ETER") {}
}