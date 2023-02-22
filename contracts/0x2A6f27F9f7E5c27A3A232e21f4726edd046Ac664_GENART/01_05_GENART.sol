// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Peppe Spray GENESIS Art
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//       _____________   _____________ _________    //
//      / ____/ ____/ | / / ____/ ___//  _/ ___/    //
//     / / __/ __/ /  |/ / __/  \__ \ / / \__ \     //
//    / /_/ / /___/ /|  / /___ ___/ // / ___/ /     //
//    \____/_____/_/ |_/_____//____/___//____/      //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract GENART is ERC1155Creator {
    constructor() ERC1155Creator("Peppe Spray GENESIS Art", "GENART") {}
}