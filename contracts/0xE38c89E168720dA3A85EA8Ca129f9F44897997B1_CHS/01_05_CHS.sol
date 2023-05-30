// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chains
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                                                  //
//                                                  //
//    _________ .__           .__                   //
//    \_   ___ \|  |__ _____  |__| ____   ______    //
//    /    \  \/|  |  \\__  \ |  |/    \ /  ___/    //
//    \     \___|   Y  \/ __ \|  |   |  \\___ \     //
//     \______  /___|  (____  /__|___|  /____  >    //
//            \/     \/     \/        \/     \/     //
//                                                  //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract CHS is ERC721Creator {
    constructor() ERC721Creator("Chains", "CHS") {}
}