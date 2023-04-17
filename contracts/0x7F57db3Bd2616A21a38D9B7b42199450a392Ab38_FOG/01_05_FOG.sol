// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fog period
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//                                                    //
//    ###                          #        #         //
//    #   ### ###     ### ### ###     ### ###         //
//    ##  # # # #     # # ##  #    #  # # # #         //
//    #   ###  ##     ### ### #    ## ### ###         //
//    #       ###     #                               //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract FOG is ERC721Creator {
    constructor() ERC721Creator("Fog period", "FOG") {}
}