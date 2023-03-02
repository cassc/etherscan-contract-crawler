// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Renaissance & Rebirth
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//      #####  #######  #####  ### ####### ####### #     # #     #     //
//     #     # #     # #     #  #  #          #    #     #  #   #      //
//     #       #     # #        #  #          #    #     #   # #       //
//      #####  #     # #        #  #####      #    #######    #        //
//           # #     # #        #  #          #    #     #    #        //
//     #     # #     # #     #  #  #          #    #     #    #        //
//      #####  #######  #####  ### #######    #    #     #    #        //
//                                                                     //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


contract SDG is ERC721Creator {
    constructor() ERC721Creator("Renaissance & Rebirth", "SDG") {}
}