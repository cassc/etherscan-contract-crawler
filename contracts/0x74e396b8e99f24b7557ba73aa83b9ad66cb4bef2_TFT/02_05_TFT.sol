// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Trash Fire Tavern
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
//                                                                                     //
//                                                                                     //
//                                                                                     //
//      *   )                        )                                                 //
//    ` )  /(   (        )        ( /(                                                 //
//     ( )(_))  )(    ( /(   (    )\())                                                //
//    (_(_())  (()\   )(_))  )\  ((_)\                                                 //
//    |_   _|   ((_) ((_)_  ((_) | |(_)                                                //
//      | |    | '_| / _` | (_-< | ' \                                                 //
//      |_|    |_|   \__,_| /__/ |_||_|                                                //
//                                                                                     //
//     (                                                                               //
//     )\ )                                                                            //
//    (()/(   (    (       (                                                           //
//     /(_))  )\   )(     ))\                                                          //
//    (_))_| ((_) (()\   /((_)                                                         //
//    | |_    (_)  ((_) (_))                                                           //
//    | __|   | | | '_| / -_)                                                          //
//    |_|     |_| |_|   \___|                                                          //
//                                                                                     //
//                                                                                     //
//      *   )                                                                          //
//    ` )  /(      )     )       (    (                                                //
//     ( )(_))  ( /(    /((     ))\   )(     (                                         //
//    (_(_())   )(_))  (_))\   /((_) (()\    )\ )                                      //
//    |_   _|  ((_)_   _)((_) (_))    ((_)  _(_/(                                      //
//      | |    / _` |  \ V /  / -_)  | '_| | ' \))                                     //
//      |_|    \__,_|   \_/   \___|  |_|   |_||_|                                      //
//                                                                                     //
//                                                                                     //
//                                                                                     //
//                                                                                     //
//                                                                                     //
//                                                                                     //
//                                                                                     //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////


contract TFT is ERC721Creator {
    constructor() ERC721Creator("Trash Fire Tavern", "TFT") {}
}