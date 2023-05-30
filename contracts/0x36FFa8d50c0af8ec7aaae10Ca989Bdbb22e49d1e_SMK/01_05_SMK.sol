// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Seimaiki
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//                                                        //
//      #              ##                  ## # #         //
//      #            ##   ##########     ##    #   #      //
//    ##########   ## #           #    ## #   # # #       //
//      #     #  ##   #          #   ##   #      #        //
//      #             #       # #         #     # #       //
//      #             #        #          #    #   #      //
//       ######       #         #         #         #     //
//                                                        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract SMK is ERC721Creator {
    constructor() ERC721Creator("Seimaiki", "SMK") {}
}