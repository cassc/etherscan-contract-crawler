// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Andrea EAR Orecchio
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//    ___________  _____ __________                        //
//    \_   _____/ /  _  \\______   \    _____    ____      //
//     |    __)_ /  /_\  \|       _/    \__  \  /  _ \     //
//     |        /    |    |    |   \     / __ \(  <_> )    //
//    /_______  \____|__  |____|_  _____(____  /\____/     //
//            \/        \/       \/_____/    \/            //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract EARao is ERC721Creator {
    constructor() ERC721Creator("Andrea EAR Orecchio", "EARao") {}
}