// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AI Banditos
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                       //
//                                                                                                                                                       //
//                                                                                                                                                       //
//               _____   ____                  _ _ _              _              _____                    _   _             _____                _       //
//         /\   |_   _| |  _ \                | (_) |            | |            / ____|                  | | | |           / ____|              | |      //
//        /  \    | |   | |_) | __ _ _ __   __| |_| |_ ___  ___  | |__  _   _  | |  __  ___ _ __   ___   | |_| |__   ___  | |  __ _ __ ___  __ _| |_     //
//       / /\ \   | |   |  _ < / _` | '_ \ / _` | | __/ _ \/ __| | '_ \| | | | | | |_ |/ _ \ '_ \ / _ \  | __| '_ \ / _ \ | | |_ | '__/ _ \/ _` | __|    //
//      / ____ \ _| |_  | |_) | (_| | | | | (_| | | || (_) \__ \ | |_) | |_| | | |__| |  __/ | | | (_) | | |_| | | |  __/ | |__| | | |  __/ (_| | |_     //
//     /_/    \_\_____| |____/ \__,_|_| |_|\__,_|_|\__\___/|___/ |_.__/ \__, |  \_____|\___|_| |_|\___/   \__|_| |_|\___|  \_____|_|  \___|\__,_|\__|    //
//                                                                       __/ |                                                                           //
//                                                                      |___/                                                                            //
//                                                                                                                                                       //
//                                                                                                                                                       //
//                                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AIB is ERC721Creator {
    constructor() ERC721Creator("AI Banditos", "AIB") {}
}