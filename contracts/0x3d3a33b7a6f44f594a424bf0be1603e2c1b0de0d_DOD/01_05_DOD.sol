// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Doors of Desitny
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//                                                     //
//          ______                                     //
//       ,-' ;  ! `-.                                  //
//      / :  !  :  . \                                 //
//     |_ ;   __:  ;  |                                //
//     )| .  :)(.  !  |                                //
//     |"    (##)  _  |                                //
//     |  :  ;`'  (_) (                                //
//     |  :  :  .     |                                //
//     )_ !  ,  ;  ;  |                                //
//     || .  .  :  :  |                                //
//     |" .  |  :  .  |                                //
//     |mt-2_;----.___|                                //
//                                                     //
//     888                                             //
//         888                                         //
//         888                                         //
//     .d88888 .d88b.  .d88b. 888d888                  //
//    d88" 888d88""88bd88""88b888P"                    //
//    888  888888  888888  888888                      //
//    Y88b 888Y88..88PY88..88P888                      //
//     "Y88888 "Y88P"  "Y88P" 888                      //
//                                                     //
//                                                     //
//                                                     //
//                                                     //
//                                                     //
//                                                     //
//    	                                                //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract DOD is ERC721Creator {
    constructor() ERC721Creator("Doors of Desitny", "DOD") {}
}