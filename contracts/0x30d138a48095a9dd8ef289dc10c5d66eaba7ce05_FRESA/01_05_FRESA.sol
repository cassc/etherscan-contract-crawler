// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: fresa editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//     ___        _     _                              //
//    (  _`\     ( ) _ ( )_  _                         //
//    | (_(_)   _| |(_)| ,_)(_)   _     ___    ___     //
//    |  _)_  /'_` || || |  | | /'_`\ /' _ `\/',__)    //
//    | (_( )( (_| || || |_ | |( (_) )| ( ) |\__, \    //
//    (____/'`\__,_)(_)`\__)(_)`\___/'(_) (_)(____/    //
//                                                     //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract FRESA is ERC1155Creator {
    constructor() ERC1155Creator("fresa editions", "FRESA") {}
}