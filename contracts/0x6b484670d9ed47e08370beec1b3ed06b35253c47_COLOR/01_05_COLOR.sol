// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Color Block
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                    //
//                                                                                                                    //
//             .----------------.  .----------------.  .----------------.  .----------------.                         //
//            | .--------------. || .--------------. || .--------------. || .--------------. |                        //
//            | |  _________   | || |   _____      | || |      __      | || |  _________   | |                        //
//            | | |_   ___  |  | || |  |_   _|     | || |     /  \     | || | |  _   _  |  | |                        //
//            | |   | |_  \_|  | || |    | |       | || |    / /\ \    | || | |_/ | | \_|  | |                        //
//            | |   |  _|      | || |    | |   _   | || |   / ____ \   | || |     | |      | |                        //
//            | |  _| |_       | || |   _| |__/ |  | || | _/ /    \ \_ | || |    _| |_     | |                        //
//            | | |_____|      | || |  |________|  | || ||____|  |____|| || |   |_____|    | |                        //
//            | |              | || |              | || |              | || |              | |                        //
//            | '--------------' || '--------------' || '--------------' || '--------------' |                        //
//             '----------------'  '----------------'  '----------------'  '----------------'                         //
//     .----------------.  .----------------.  .----------------.  .----------------.  .----------------.             //
//    | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |            //
//    | |     ______   | || |     ____     | || |   _____      | || |     ____     | || |  _______     | |            //
//    | |   .' ___  |  | || |   .'    `.   | || |  |_   _|     | || |   .'    `.   | || | |_   __ \    | |            //
//    | |  / .'   \_|  | || |  /  .--.  \  | || |    | |       | || |  /  .--.  \  | || |   | |__) |   | |            //
//    | |  | |         | || |  | |    | |  | || |    | |   _   | || |  | |    | |  | || |   |  __ /    | |            //
//    | |  \ `.___.'\  | || |  \  `--'  /  | || |   _| |__/ |  | || |  \  `--'  /  | || |  _| |  \ \_  | |            //
//    | |   `._____.'  | || |   `.____.'   | || |  |________|  | || |   `.____.'   | || | |____| |___| | |            //
//    | |              | || |              | || |              | || |              | || |              | |            //
//    | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |            //
//     '----------------'  '----------------'  '----------------'  '----------------'  '----------------'             //
//     .----------------.  .----------------.  .----------------.  .----------------.  .----------------.             //
//    | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |            //
//    | |   ______     | || |   _____      | || |     ____     | || |     ______   | || |  ___  ____   | |            //
//    | |  |_   _ \    | || |  |_   _|     | || |   .'    `.   | || |   .' ___  |  | || | |_  ||_  _|  | |            //
//    | |    | |_) |   | || |    | |       | || |  /  .--.  \  | || |  / .'   \_|  | || |   | |_/ /    | |            //
//    | |    |  __'.   | || |    | |   _   | || |  | |    | |  | || |  | |         | || |   |  __'.    | |            //
//    | |   _| |__) |  | || |   _| |__/ |  | || |  \  `--'  /  | || |  \ `.___.'\  | || |  _| |  \ \_  | |            //
//    | |  |_______/   | || |  |________|  | || |   `.____.'   | || |   `._____.'  | || | |____||____| | |            //
//    | |              | || |              | || |              | || |              | || |              | |            //
//    | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |            //
//     '----------------'  '----------------'  '----------------'  '----------------'  '----------------'             //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract COLOR is ERC721Creator {
    constructor() ERC721Creator("Color Block", "COLOR") {}
}