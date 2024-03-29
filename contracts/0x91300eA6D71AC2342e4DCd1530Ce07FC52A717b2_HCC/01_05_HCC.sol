// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Happy!
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//      _    _            _____   _____ __     __ _     //
//     | |  | |    /\    |  __ \ |  __ \\ \   / /| |    //
//     | |__| |   /  \   | |__) || |__) |\ \_/ / | |    //
//     |  __  |  / /\ \  |  ___/ |  ___/  \   /  | |    //
//     | |  | | / ____ \ | |     | |       | |   |_|    //
//     |_|  |_|/_/    \_\|_|     |_|       |_|   (_)    //
//      _                                               //
//     | |                                              //
//     | |__   _   _                                    //
//     | '_ \ | | | |                                   //
//     | |_) || |_| |                                   //
//     |_.__/  \__, |                                   //
//              __/ |                                   //
//             |___/                                    //
//       _____  _                                       //
//      / ____|| |                                      //
//     | |     | |__    __ _  _ __  ___   _ __          //
//     | |     | '_ \  / _` || '__|/ _ \ | '_ \         //
//     | |____ | | | || (_| || |  | (_) || | | |        //
//      \_____||_| |_| \__,_||_|   \___/ |_| |_|        //
//       _____                      _                   //
//      / ____|                    | |                  //
//     | |      _ __  _   _  _ __  | |_  ___            //
//     | |     | '__|| | | || '_ \ | __|/ _ \           //
//     | |____ | |   | |_| || |_) || |_| (_) |          //
//      \_____||_|    \__, || .__/  \__|\___/           //
//                     __/ || |                         //
//                    |___/ |_|                         //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract HCC is ERC1155Creator {
    constructor() ERC1155Creator("Happy!", "HCC") {}
}