// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: IMAGINARY EDITIONS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////
//                                                                 //
//                                                                 //
//        ______  ______   ___________   _____    ______  __       //
//       /  _/  |/  /   | / ____/  _/ | / /   |  / __ \ \/ /       //
//       / // /|_/ / /| |/ / __ / //  |/ / /| | / /_/ /\  /        //
//     _/ // /  / / ___ / /_/ // // /|  / ___ |/ _, _/ / /         //
//    /___/_/__/_/_/  |_\____/___/_/_|_/_/_ |_/_/_|_| /_/          //
//          / ____/ __ \/  _/_  __/  _/ __ \/ | / / ___/           //
//         / __/ / / / // /  / /  / // / / /  |/ /\__ \            //
//        / /___/ /_/ // /  / / _/ // /_/ / /|  /___/ /            //
//       /_____/_____/___/ /_/ /___/\____/_/ |_//____/             //
//                                  by Imaginary Sina              //
//                                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


contract IMGE is ERC1155Creator {
    constructor() ERC1155Creator("IMAGINARY EDITIONS", "IMGE") {}
}