// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Brotherz in the Hood
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//    ..%%%%....%%%%...%%%%%...%%%%%....%%%%..    //
//    .%%......%%..%%..%%..%%..%%..%%..%%..%%.    //
//    .%%.%%%..%%..%%..%%%%%...%%..%%..%%..%%.    //
//    .%%..%%..%%..%%..%%..%%..%%..%%..%%..%%.    //
//    ..%%%%....%%%%...%%..%%..%%%%%....%%%%..    //
//    ........................................    //
//                                                //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract Gordo is ERC721Creator {
    constructor() ERC721Creator("Brotherz in the Hood", "Gordo") {}
}