// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THYCUKE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
//                                                                                     //
//                                                                                     //
//     _____ ___________  ___  ___          _        _                                 //
//    /  __ \  _  | ___ \ |  \/  |         | |      | |                                //
//    | /  \/ | | | |_/ / | .  . | __ _  __| | ___  | |__  _   _                       //
//    | |   | | | |    /  | |\/| |/ _` |/ _` |/ _ \ | '_ \| | | |                      //
//    | \__/\ \_/ / |\ \  | |  | | (_| | (_| |  __/ | |_) | |_| |                      //
//     \____/\___/\_| \_| \_|  |_/\__,_|\__,_|\___| |_.__/ \__, |                      //
//                                                          __/ |                      //
//                                                         |___/                       //
//    @TrueNoir_                                                                       //
//    @IrlMoral                                                                        //
//                                                                                     //
//    This Digital Cucumber may or may not hold the answers to the universe, All we    //
//    know for sure is that it is great for hydration.                                 //
//                                                                                     //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////


contract CUMBR is ERC1155Creator {
    constructor() ERC1155Creator("THYCUKE", "CUMBR") {}
}