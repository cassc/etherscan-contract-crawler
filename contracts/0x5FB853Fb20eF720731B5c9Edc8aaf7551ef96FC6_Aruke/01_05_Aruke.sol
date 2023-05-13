// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kōya o Aruke
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//       _____               __               //
//      /  _  \_______ __ __|  | __ ____      //
//     /  /_\  \_  __ \  |  \  |/ // __ \     //
//    /    |    \  | \/  |  /    <\  ___/     //
//    \____|__  /__|  |____/|__|_ \\___  >    //
//            \/                 \/    \/     //
//                                            //
//                                            //
////////////////////////////////////////////////


contract Aruke is ERC721Creator {
    constructor() ERC721Creator(unicode"Kōya o Aruke", "Aruke") {}
}