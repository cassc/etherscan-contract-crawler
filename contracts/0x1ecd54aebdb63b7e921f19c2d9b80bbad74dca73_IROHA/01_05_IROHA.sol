// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: IROHA
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//                                     //
//          ##                         //
//        ##   #########               //
//      ## #   #       #    #  #       //
//    ##   #   #       #   #    #      //
//         #   #       #  #      #     //
//         #   ######### #             //
//         #                           //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract IROHA is ERC721Creator {
    constructor() ERC721Creator("IROHA", "IROHA") {}
}