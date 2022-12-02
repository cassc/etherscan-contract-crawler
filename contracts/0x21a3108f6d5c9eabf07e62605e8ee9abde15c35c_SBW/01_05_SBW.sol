// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Street in Black and White
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                           //
//                                                                                           //
//                                                                                           //
//                                                                                           //
//       SSSSSSSSSSSSSSS BBBBBBBBBBBBBBBBB   WWWWWWWW                           WWWWWWWW     //
//     SS:::::::::::::::SB::::::::::::::::B  W::::::W                           W::::::W     //
//    S:::::SSSSSS::::::SB::::::BBBBBB:::::B W::::::W                           W::::::W     //
//    S:::::S     SSSSSSSBB:::::B     B:::::BW::::::W                           W::::::W     //
//    S:::::S              B::::B     B:::::B W:::::W           WWWWW           W:::::W      //
//    S:::::S              B::::B     B:::::B  W:::::W         W:::::W         W:::::W       //
//     S::::SSSS           B::::BBBBBB:::::B    W:::::W       W:::::::W       W:::::W        //
//      SS::::::SSSSS      B:::::::::::::BB      W:::::W     W:::::::::W     W:::::W         //
//        SSS::::::::SS    B::::BBBBBB:::::B      W:::::W   W:::::W:::::W   W:::::W          //
//           SSSSSS::::S   B::::B     B:::::B      W:::::W W:::::W W:::::W W:::::W           //
//                S:::::S  B::::B     B:::::B       W:::::W:::::W   W:::::W:::::W            //
//                S:::::S  B::::B     B:::::B        W:::::::::W     W:::::::::W             //
//    SSSSSSS     S:::::SBB:::::BBBBBB::::::B         W:::::::W       W:::::::W              //
//    S::::::SSSSSS:::::SB:::::::::::::::::B           W:::::W         W:::::W               //
//    S:::::::::::::::SS B::::::::::::::::B             W:::W           W:::W                //
//     SSSSSSSSSSSSSSS   BBBBBBBBBBBBBBBBB               WWW             WWW                 //
//                                                                                           //
//                                                                                           //
//                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////


contract SBW is ERC721Creator {
    constructor() ERC721Creator("Street in Black and White", "SBW") {}
}