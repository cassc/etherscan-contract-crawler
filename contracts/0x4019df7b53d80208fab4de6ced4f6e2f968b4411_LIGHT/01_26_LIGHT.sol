// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: with the light
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//         #   #  #        #  #            #   #      #    #     //
//    # #     ### ###     ### ### ###      #      ### ### ###    //
//    ###  #   #  # #      #  # # ##       #   #  # # # #  #     //
//    ###  ##  ## # #      ## # # ###      ##  ##  ## # #  ##    //
//                                                ###            //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract LIGHT is ERC721Creator {
    constructor() ERC721Creator("with the light", "LIGHT") {}
}