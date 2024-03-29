// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Animals outside of America
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//                                                                          //
//                                                                          //
//     ________                                                             //
//    |        \                                                            //
//     \$$$$$$$$______    _______  ______  __     __  ______    ______      //
//       | $$  |      \  /       \|      \|  \   /  \|      \  /      \     //
//       | $$   \$$$$$$\|  $$$$$$$ \$$$$$$\\$$\ /  $$ \$$$$$$\|  $$$$$$\    //
//       | $$  /      $$| $$      /      $$ \$$\  $$ /      $$| $$   \$$    //
//       | $$ |  $$$$$$$| $$_____|  $$$$$$$  \$$ $$ |  $$$$$$$| $$          //
//       | $$  \$$    $$ \$$     \\$$    $$   \$$$   \$$    $$| $$          //
//        \$$   \$$$$$$$  \$$$$$$$ \$$$$$$$    \$     \$$$$$$$ \$$          //
//                                                                          //
//                                                                          //
//                                                                          //
//                                                                          //
//                                                                          //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////


contract AooA is ERC1155Creator {
    constructor() ERC1155Creator("Animals outside of America", "AooA") {}
}