// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Inflatables
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//                                           //
//    .-.       .--..-.         .-.          //
//    : :      : .-': :        .' `.         //
//    : :,-.,-.: `; : :   .--. `. .'.--.     //
//    : :: ,. :: :  : :_ ' .; ; : :' '_.'    //
//    :_;:_;:_;:_;  `.__;`.__,_;:_;`.__.'    //
//                                           //
//                                           //
//                                           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract INFL is ERC721Creator {
    constructor() ERC721Creator("Inflatables", "INFL") {}
}