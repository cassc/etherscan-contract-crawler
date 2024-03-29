// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tormius
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                ████████╗ ██████╗ ██████╗ ███╗   ███╗██╗██╗   ██╗███████╗               //
//                ╚══██╔══╝██╔═══██╗██╔══██╗████╗ ████║██║██║   ██║██╔════╝               //
//                   ██║   ██║   ██║██████╔╝██╔████╔██║██║██║   ██║███████╗               //
//                   ██║   ██║   ██║██╔══██╗██║╚██╔╝██║██║██║   ██║╚════██║               //
//                   ██║   ╚██████╔╝██║  ██║██║ ╚═╝ ██║██║╚██████╔╝███████║               //
//                   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚═╝ ╚═════╝ ╚══════╝               //
//                                                                                        //
//                                                                                        //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@                        [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@*                                     @@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@%                 @(.........%&                [email protected]@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@&                 *,.........*    @..%                 ,@@@@@@@@@@@@    //
//    @@@@@@@@@.                  /[email protected]@@@@@      /...,.                  @@@@@@@@@    //
//    @@@@@@,                    @....#@@@@@@@@@/  @@@[email protected]                    @@@@@@    //
//    @@@@                      %[email protected]@@@@@@@@@@@@@@@@@#....                       @@@    //
//    @#                        @............%@@@@@@@@@@[email protected]                        @    //
//    @@@                       @[email protected]@@@@@@@@@@@@@@@@@@....%                       @@    //
//    @@@@@%                     ,[email protected]@@@@@@@@@@@@@@@@[email protected]                     ,@@@@    //
//    @@@@@@@@*                   #....*@@@@@@@@@@@@@[email protected]                    @@@@@@@    //
//    @@@@@@@@@@@&                 *,......,@@@@&.......(                  ,@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@.                @,.............(%                 @@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@&                  *&@%,                  *@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@                               @@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     //
//                                                                                        //
//             _   __              ____                         _                         //
//            / | / /___   ____   / __/____   _____ ____ ___   (_)_____ ____ ___          //
//           /  |/ // _ \ / __ \ / /_ / __ \ / ___// __ `__ \ / // ___// __ `__ \         //
//          / /|  //  __// /_/ // __// /_/ // /   / / / / / // /(__  )/ / / / / /         //
//         /_/ |_/ \___/ \____//_/   \____//_/   /_/ /_/ /_//_//____//_/ /_/ /_/          //
//                                                                                        //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract TORM is ERC721Creator {
    constructor() ERC721Creator("Tormius", "TORM") {}
}