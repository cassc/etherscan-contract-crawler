// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: All Around Artsy
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//             /\           /\           /\       //
//         _  / |       _  / |       _  / |       //
//        (  /  |  .   (  /  |  .   (  /  |  .    //
//         `/.__|_.'    `/.__|_.'    `/.__|_.'    //
//     .:' /    |   .:' /    |   .:' /    |       //
//    (__.'     `-'(__.'     `-'(__.'     `-'     //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract AAA is ERC721Creator {
    constructor() ERC721Creator("All Around Artsy", "AAA") {}
}