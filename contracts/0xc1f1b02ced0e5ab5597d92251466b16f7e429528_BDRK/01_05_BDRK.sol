// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Beautiful Darkness
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//    <-.(`-') _(`-')      (`-') <-.(`-')      //
//     __( OO)( (OO ).-><-.(OO )  __( OO)      //
//    '-'---.\ \    .'_ ,------,)'-'. ,--.     //
//    | .-. (/ '`'-..__)|   /`. '|  .'   /     //
//    | '-' `.)|  |  ' ||  |_.' ||      /)     //
//    | /`'.  ||  |  / :|  .   .'|  .   '      //
//    | '--'  /|  '-'  /|  |\  \ |  |\   \     //
//    `------' `------' `--' '--'`--' '--'     //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract BDRK is ERC721Creator {
    constructor() ERC721Creator("Beautiful Darkness", "BDRK") {}
}