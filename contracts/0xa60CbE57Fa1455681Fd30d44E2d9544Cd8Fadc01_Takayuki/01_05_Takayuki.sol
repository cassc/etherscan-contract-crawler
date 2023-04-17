// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Life Of Takayuki
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//    #######                                                //
//       #      ##   #    #   ##   #   # #    # #    # #     //
//       #     #  #  #   #   #  #   # #  #    # #   #  #     //
//       #    #    # ####   #    #   #   #    # ####   #     //
//       #    ###### #  #   ######   #   #    # #  #   #     //
//       #    #    # #   #  #    #   #   #    # #   #  #     //
//       #    #    # #    # #    #   #    ####  #    # #     //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract Takayuki is ERC1155Creator {
    constructor() ERC1155Creator("The Life Of Takayuki", "Takayuki") {}
}