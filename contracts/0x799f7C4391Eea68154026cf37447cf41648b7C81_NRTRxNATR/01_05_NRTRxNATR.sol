// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Crimes Against Our Nature
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//          ,---.                ,---.     ____    ,---.    ,---.     //
//         /,--.|               /,--.|   .'  __ `. |    \  /    |     //
//        //_  ||              //_  ||  /   '  \  \|  ,  \/  ,  |     //
//       /_( )_||             /_( )_||  |___|  /  ||  |\_   /|  |     //
//      /(_ o _)|            /(_ o _)|     _.-`   ||  _( )_/ |  |     //
//     / /(_,_)||_          / /(_,_)||_ .'   _/|  || (_ o _) |  |     //
//    /  `-----' ||        /  `-----' |||  _( )_  ||  (_,_)  |  |     //
//    `-------|||-'        `-------|||-'\ (_ o _) /|  |      |  |     //
//            '-'           ,---.  '-'   '.(_,_).' '--'      '--'     //
//                         /,--.|                                     //
//                        //_  ||                                     //
//                       /_( )_||                                     //
//                      /(_ o _)|                                     //
//                     / /(_,_)||_                                    //
//                    /  `-----' ||                                   //
//                    `-------|||-'                                   //
//                            '-'                                     //
//                                                                    //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract NRTRxNATR is ERC721Creator {
    constructor() ERC721Creator("Crimes Against Our Nature", "NRTRxNATR") {}
}