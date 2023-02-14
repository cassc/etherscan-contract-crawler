// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hot Potato [Ordinal Token]
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//      ___ ___         __    __________       __          __              //
//     /   |   \  _____/  |_  \______   \_____/  |______ _/  |_  ____      //
//    /    ~    \/  _ \   __\  |     ___/  _ \   __\__  \\   __\/  _ \     //
//    \    Y    (  <_> )  |    |    |  (  <_> )  |  / __ \|  | (  <_> )    //
//     \___|_  / \____/|__|    |____|   \____/|__| (____  /__|  \____/     //
//           \/                                         \/                 //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract HOTPOT is ERC721Creator {
    constructor() ERC721Creator("Hot Potato [Ordinal Token]", "HOTPOT") {}
}