// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tropical Toy
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//    ___________                    .__                   //
//    \__    ___/______  ____ ______ |__| ____   ______    //
//      |    |  \_  __ \/  _ \\____ \|  |/ ___\ /  ___/    //
//      |    |   |  | \(  <_> )  |_> >  \  \___ \___ \     //
//      |____|   |__|   \____/|   __/|__|\___  >____  >    //
//                            |__|           \/     \/     //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract TTOY is ERC1155Creator {
    constructor() ERC1155Creator("Tropical Toy", "TTOY") {}
}