// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Stef's Editions '23
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                               //
//                                                                                                                               //
//     .oooooo..o ooooooooooooo oooooooooooo oooooooooo.   ooooo ooooooooooooo ooooo   .oooooo.   ooooo      ooo  .oooooo..o     //
//    d8P'    `Y8 8'   888   `8 `888'     `8 `888'   `Y8b  `888' 8'   888   `8 `888'  d8P'  `Y8b  `888b.     `8' d8P'    `Y8     //
//    Y88bo.           888       888          888      888  888       888       888  888      888  8 `88b.    8  Y88bo.          //
//     `"Y8888o.       888       888oooo8     888      888  888       888       888  888      888  8   `88b.  8   `"Y8888o.      //
//         `"Y88b      888       888    "     888      888  888       888       888  888      888  8     `88b.8       `"Y88b     //
//    oo     .d8P      888       888       o  888     d88'  888       888       888  `88b    d88'  8       `888  oo     .d8P     //
//    8""88888P'      o888o     o888ooooood8 o888bood8P'   o888o     o888o     o888o  `Y8bood8P'  o8o        `8  8""88888P'      //
//                                                                                                                               //
//                                                                                                                               //
//                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract STEDITIONS23 is ERC1155Creator {
    constructor() ERC1155Creator("Stef's Editions '23", "STEDITIONS23") {}
}