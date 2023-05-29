// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Occultoken
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//                     _       //
//                     \`\     //
//           /./././.   | |    //
//         /        `/. | |    //
//        /     __    `/'/'    //
//     /\__/\ /'  `\    /      //
//    |  oo  |      `.,.|      //
//     \vvvv/        ||||      //
//       ||||        ||||      //
//       ||||        ||||      //
//       `'`'        `'`'      //
//                             //
//                             //
/////////////////////////////////


contract OCCULTOKEN is ERC721Creator {
    constructor() ERC721Creator("Occultoken", "OCCULTOKEN") {}
}