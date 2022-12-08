// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: meragana on chain
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//                                                            //
//             #   ######        #     ### ###      #         //
//            #             ########## ### ### ##########     //
//       #   #   ##########     #    #  #   #       #         //
//        # #    #        #     #    #              #         //
//         #            ##     #     #             #          //
//       ## #         ##      #   # #             #           //
//     ##    #      ##       #     #            ##            //
//                                                            //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract MGOC is ERC721Creator {
    constructor() ERC721Creator("meragana on chain", "MGOC") {}
}