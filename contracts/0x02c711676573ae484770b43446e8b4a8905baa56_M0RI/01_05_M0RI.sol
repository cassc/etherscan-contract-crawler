// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Damane a’Csambre
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//     _   .-')                _  .-')               //
//    ( '.( OO )_             ( \( -O )              //
//     ,--.   ,--.).-'),-----. ,------.  ,-.-')      //
//     |   `.'   |( OO'  .-.  '|   /`. ' |  |OO)     //
//     |         |/   |  | |  ||  /  | | |  |  \     //
//     |  |'.'|  |\_) |  |\|  ||  |_.' | |  |(_/     //
//     |  |   |  |  \ |  | |  ||  .  '.',|  |_.'     //
//     |  |   |  |   `'  '-'  '|  |\  \(_|  |        //
//     `--'   `--'     `-----' `--' '--' `--'        //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract M0RI is ERC1155Creator {
    constructor() ERC1155Creator(unicode"Damane a’Csambre", "M0RI") {}
}