// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Artificial Childhood Memories
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//                                            //
//                                            //
//             /\     .-._   .-._..-.         //
//         _  / |   .: (_)`-'      .;|/:      //
//        (  /  |  .::            .;   :      //
//         `/.__|_.'::   _       .;    :      //
//     .:' /    |   `: .; )  .:'.;     :      //
//    (__.'     `-'   `--'  (__.'      `.     //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract ACM is ERC721Creator {
    constructor() ERC721Creator("Artificial Childhood Memories", "ACM") {}
}