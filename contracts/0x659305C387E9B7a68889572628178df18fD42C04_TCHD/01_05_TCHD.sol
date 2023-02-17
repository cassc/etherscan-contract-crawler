// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Technicolor Dreams
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//    #                       #     ##########               #   #     //
//    #   ###  #########   #######  #        #   #########   #   #     //
//    ####     #       #    # #             #    #       #   #   #     //
//    #        #       #    # #            #     #       #   #   #     //
//    #        #       # ##########       #      #       #      #      //
//    #        #########      #         ##       #########     #       //
//     #######                #       ##                     ##        //
//                                                                     //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


contract TCHD is ERC1155Creator {
    constructor() ERC1155Creator("Technicolor Dreams", "TCHD") {}
}