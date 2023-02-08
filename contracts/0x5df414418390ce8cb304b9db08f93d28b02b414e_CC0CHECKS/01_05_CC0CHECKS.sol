// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CC0 CHECKS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////
//                                                                //
//                                                                //
//                                                                //
//                                                                //
//    #   # #   # ###     #   # #   # ##### #   # #   #  ####     //
//    #   # #   # # #     #   #  # #  #     #   # #  #  #         //
//     ####  #### # #      ####   #   ####   #### ###   #         //
//        #     # # #         #  # #  #         # #  #  #         //
//        #     # ###         # #   # #####     # #   #  ####     //
//                                                                //
//                                                                //
//                                                                //
////////////////////////////////////////////////////////////////////


contract CC0CHECKS is ERC721Creator {
    constructor() ERC721Creator("CC0 CHECKS", "CC0CHECKS") {}
}