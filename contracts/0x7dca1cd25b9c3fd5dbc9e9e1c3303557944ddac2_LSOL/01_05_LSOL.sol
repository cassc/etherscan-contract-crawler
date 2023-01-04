// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Skull of Life
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//                                    //
//         ## #        #   #          //
//        #   # # # #  #   #          //
//         #  ##  # #  #   #          //
//          # # # ###  ##  ##         //
//        ##                          //
//                                    //
//         ##     #    #   ##         //
//    ###  #      #        #  ###     //
//    # # ###     #    #  ### ##      //
//    ###  #      #    ##  #  ###     //
//        ##      ###     ##          //
//                                    //
//                                    //
////////////////////////////////////////


contract LSOL is ERC721Creator {
    constructor() ERC721Creator("Skull of Life", "LSOL") {}
}