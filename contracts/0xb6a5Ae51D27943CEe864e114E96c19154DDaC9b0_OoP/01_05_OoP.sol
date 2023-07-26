// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OuT oF PoCkEt
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                 _ (`-.      //
//                                ( (OO  )     //
//     .-'),-----.  .-'),-----.  _.`     \     //
//    ( OO'  .-.  '( OO'  .-.  '(__...--''     //
//    /   |  | |  |/   |  | |  | |  /  | |     //
//    \_) |  |\|  |\_) |  |\|  | |  |_.' |     //
//      \ |  | |  |  \ |  | |  | |  .___.'     //
//       `'  '-'  '   `'  '-'  ' |  |          //
//         `-----'      `-----'  `--'          //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract OoP is ERC721Creator {
    constructor() ERC721Creator("OuT oF PoCkEt", "OoP") {}
}