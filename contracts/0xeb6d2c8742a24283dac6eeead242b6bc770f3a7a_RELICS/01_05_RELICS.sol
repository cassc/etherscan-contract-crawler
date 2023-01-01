// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rye's Relics
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////
//                                                                        //
//                                                                        //
//       _____            _       _____      _ _                          //
//      |  __ \          ( )     |  __ \    | (_)                         //
//      | |__) |   _  ___|/ ___  | |__) |___| |_  ___ ___                 //
//      |  _  / | | |/ _ \ / __| |  _  // _ \ | |/ __/ __|                //
//      | | \ \ |_| |  __/ \__ \ | | \ \  __/ | | (__\__ \                //
//      |_|  \_\__, |\___| |___/ |_|  \_\___|_|_|\___|___/                //
//              __/ |                                                     //
//             |___/  ┌─┐  ┌┐ ┬  ┌─┐┌─┐┬┌─┌─┐┬ ┬┌─┐┬┌┐┌  ┌─┐┌─┐┌┬┐┌─┐     //
//                    ├─┤  ├┴┐│  │ ││  ├┴┐│  ├─┤├─┤││││  │ ┬├─┤│││├┤      //
//                    ┴ ┴  └─┘┴─┘└─┘└─┘┴ ┴└─┘┴ ┴┴ ┴┴┘└┘  └─┘┴ ┴┴ ┴└─┘     //
//                _    .  ,   .           .                               //
//            *  / \_ *  / \_      _  *        *   /\'__        *         //
//              /    \  /    \,   ((        .    _/  /  \  *'.            //
//         .   /\/\  /\/ :' __ \_  `          _^/  ^/    `--.             //
//            /    \/  \  _/  \-'\      *    /.' ^_   \_   .'\  *         //
//          /\  .-   `. \/     \ /==~=-=~=-=-;.  _/ \ -. `_/   \          //
//         /  `-.__ ^   / .-'.--\ =-=~_=-=~=^/  _ `--./ .-'  `-           //
//        /.       `.  / /       `.~-^=-=~=^=.-'      '-._ `._            //
//                                                                        //
//    In Rye's Relics, you play as a young boy exploring life with        //
//    your wise step-father. Along the way, you come across five          //
//    books that contain advice from your mother and the mysterious       //
//    past of your father. As you explore these books, you must decide    //
//    which path to follow and what lessons to take with you on your      //
//    journey. You will also learn about the importance of caring for     //
//    and protecting the natural world, discovering a way to use your     //
//    love of enchanted gardening to make a difference.                   //
//                                                                        //
//     vVVVv   Rye's Relics metaverse parcels are located here:           //
//     (___)   https://www.voxels.com/[email protected],1080S           //
//      ~Y~    53 and 43 Quartz Street                                    //
//      \|/    Bronze suburb,                                             //
//    \\\|///  Scarcity Island,                                           //
//    ^^^^^^^  Voxels.com                                                 //
//                                                                        //
//                                                                        //
////////////////////////////////////////////////////////////////////////////


contract RELICS is ERC1155Creator {
    constructor() ERC1155Creator("Rye's Relics", "RELICS") {}
}