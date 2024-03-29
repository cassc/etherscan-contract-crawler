// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: UOOKOHOOK DC
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                //
//                                                                                                                                                //
//                                                                                                                                                //
//                                           .-. .-')                ('-. .-.                          .-. .-')         _ .-') _                  //
//                                           \  ( OO )              ( OO )  /                          \  ( OO )       ( (  OO) )                 //
//     ,--. ,--.    .-'),-----.  .-'),-----. ,--. ,--.  .-'),-----. ,--. ,--. .-'),-----.  .-'),-----. ,--. ,--.        \     .'_    .-----.      //
//     |  | |  |   ( OO'  .-.  '( OO'  .-.  '|  .'   / ( OO'  .-.  '|  | |  |( OO'  .-.  '( OO'  .-.  '|  .'   /        ,`'--..._)  '  .--./      //
//     |  | | .-') /   |  | |  |/   |  | |  ||      /, /   |  | |  ||   .|  |/   |  | |  |/   |  | |  ||      /,        |  |  \  '  |  |('-.      //
//     |  |_|( OO )\_) |  |\|  |\_) |  |\|  ||     ' _)\_) |  |\|  ||       |\_) |  |\|  |\_) |  |\|  ||     ' _)       |  |   ' | /_) |OO  )     //
//     |  | | `-' /  \ |  | |  |  \ |  | |  ||  .   \    \ |  | |  ||  .-.  |  \ |  | |  |  \ |  | |  ||  .   \         |  |   / : ||  |`-'|      //
//    ('  '-'(_.-'    `'  '-'  '   `'  '-'  '|  |\   \    `'  '-'  '|  | |  |   `'  '-'  '   `'  '-'  '|  |\   \        |  '--'  /(_'  '--'\      //
//      `-----'         `-----'      `-----' `--' '--'      `-----' `--' `--'     `-----'      `-----' `--' '--'        `-------'    `-----'      //
//                                                                                                                                                //
//                                                                                                                                                //
//                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract UHDC is ERC721Creator {
    constructor() ERC721Creator("UOOKOHOOK DC", "UHDC") {}
}