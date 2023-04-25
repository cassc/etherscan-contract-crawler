// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Keys of Veel-Tark
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////
//                         //
//                         //
//            ____         //
//        _  |||| _        //
//      { \`\_____//'}     //
//        \_\`\   /`/_/    //
//       /_/`\_\ /_/'\     //
//       \ \_/ \|\ \_/     //
//        \____/ \___|     //
//         ( (_/)__)       //
//          `--'  `--'     //
//                         //
//                         //
/////////////////////////////


contract vtk is ERC1155Creator {
    constructor() ERC1155Creator("The Keys of Veel-Tark", "vtk") {}
}