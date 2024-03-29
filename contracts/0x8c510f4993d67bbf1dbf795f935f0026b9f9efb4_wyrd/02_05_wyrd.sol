// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: wyrden
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                  //
//                                                                                                                                  //
//     ____ ____ ____ ____ ____ ____ ____ ____ ____ ____ ____ ____ ____ ____ ____ ____ ____ ____ ____ ____ ____ ____                //
//    |____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|               //
//                                                                                                                                  //
//    __/\\\______________/\\\__/\\\________/\\\____/\\\\\\\\\______/\\\\\\\\\\\\_____/\\\\\\\\\\\\\\\__/\\\\\_____/\\\_            //
//     _\/\\\_____________\/\\\_\///\\\____/\\\/___/\\\///////\\\___\/\\\////////\\\__\/\\\///////////__\/\\\\\\___\/\\\_           //
//      _\/\\\_____________\/\\\___\///\\\/\\\/____\/\\\_____\/\\\___\/\\\______\//\\\_\/\\\_____________\/\\\/\\\__\/\\\_          //
//       _\//\\\____/\\\____/\\\______\///\\\/______\/\\\\\\\\\\\/____\/\\\_______\/\\\_\/\\\\\\\\\\\_____\/\\\//\\\_\/\\\_         //
//        __\//\\\__/\\\\\__/\\\_________\/\\\_______\/\\\//////\\\____\/\\\_______\/\\\_\/\\\///////______\/\\\\//\\\\/\\\_        //
//         ___\//\\\/\\\/\\\/\\\__________\/\\\_______\/\\\____\//\\\___\/\\\_______\/\\\_\/\\\_____________\/\\\_\//\\\/\\\_       //
//          ____\//\\\\\\//\\\\\___________\/\\\_______\/\\\_____\//\\\__\/\\\_______/\\\__\/\\\_____________\/\\\__\//\\\\\\_      //
//           _____\//\\\__\//\\\____________\/\\\_______\/\\\______\//\\\_\/\\\\\\\\\\\\/___\/\\\\\\\\\\\\\\\_\/\\\___\//\\\\\_     //
//            ______\///____\///_____________\///________\///________\///__\////////////_____\///////////////__\///_____\/////__    //
//               ____ ____ ____ ____ ____ ____ ____ ____ ____ ____ ____ ____ ____ ____ ____ ____ ____ ____ ____ ____ ____ ____      //
//              |____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|     //
//                                                                                                                                  //
//                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract wyrd is ERC721Creator {
    constructor() ERC721Creator("wyrden", "wyrd") {}
}