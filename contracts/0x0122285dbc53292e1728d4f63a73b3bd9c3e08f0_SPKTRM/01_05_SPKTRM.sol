// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SPEKTRUM
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//                       #          #                           //
//                       #          #                           //
//      #####   # ###    #   #    #####    # ###    ### ##      //
//     #        ##   #   #  #       #      ##   #   #  #  #     //
//      ####    ##   #   # #        #      #        #  #  #     //
//          #   # ###    ## #       #  #   #        #  #  #     //
//     #####    #        #   #       ##    #        #  #  #     //
//              #                                               //
//                                                              //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract SPKTRM is ERC721Creator {
    constructor() ERC721Creator("SPEKTRUM", "SPKTRM") {}
}