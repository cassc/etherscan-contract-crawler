// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Vapor Workstations
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                                                                                                 //
//                                _______ _______ _______ _______ _______                                                          //
//                               |\     /|\     /|\     /|\     /|\     /|                                                         //
//                               | +---+ | +---+ | +---+ | +---+ | +---+ |                                                         //
//                               | |   | | |   | | |   | | |   | | |   | |                                                         //
//                               | | V | | | A | | | P | | | O | | | R | |                                                         //
//                               | +---+ | +---+ | +---+ | +---+ | +---+ |                                                         //
//                               |/_____\|/_____\|/_____\|/_____\|/_____\|                                                         //
//     _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ _______                             //
//    |\     /|\     /|\     /|\     /|\     /|\     /|\     /|\     /|\     /|\     /|\     /|\     /|                            //
//    | +---+ | +---+ | +---+ | +---+ | +---+ | +---+ | +---+ | +---+ | +---+ | +---+ | +---+ | +---+ |                            //
//    | |   | | |   | | |   | | |   | | |   | | |   | | |   | | |   | | |   | | |   | | |   | | |   | |                            //
//    | | W | | | O | | | R | | | K | | | S | | | T | | | A | | | T | | | I | | | O | | | N | | | S | |                            //
//    | +---+ | +---+ | +---+ | +---+ | +---+ | +---+ | +---+ | +---+ | +---+ | +---+ | +---+ | +---+ |                            //
//    |/_____\|/_____\|/_____\|/_____\|/_____\|/_____\|/_____\|/_____\|/_____\|/_____\|/_____\|/_____\|                            //
//                                                          .^                                                                     //
//                                                         :Y5^!..                  .:                                             //
//                                                          7#BYJ?.           : .~JG5~                                             //
//                                                           ?#PPGY:       :.?7JB&&5!.                                             //
//                                                           !###G&P:   [email protected]!.                                             //
//                                       :!7!~^^^:.         [email protected]@G#@G. J&&B&@&BP?:   .                                             //
//                                       .!YGB#BB#PY?~.^:   ^JB#&@@@@[email protected]@@@BPYJ!:^!~^?                                             //
//                                        .:[email protected]@&#&GY5J:  !&#B#@@@G#@@B5P5PP??5GGBJ7:                                           //
//                                              :!YG#&@BP#&[email protected]&@@@@&##G57GG5B&BGPJ^                                            //
//                                                 :~?YG#&@&#[email protected]@#&&[email protected]#P&@55B&#&#GJ7^                                              //
//                                                 :!?YP#&@&&[email protected]###@B&@BG&&&BJ:.                                                 //
//                                                  :~?G&@@@@#P5GGB&&[email protected]@@B555?~^^~~~^:                                             //
//                                         .^!?JJYYJ?7~~!J5B#[email protected]#!&&@B#&B######&@@@@@&&BY7^                                         //
//                                       ^JP&BBGB&#B#&&##BBGBGPGB#&&#B&BB#B#BPPPPPB#[email protected]&&BP7:                                      //
//                                     .!#Y!~!~!!^::^~?Y5G&@@&&#&@&[email protected]@&GPPGB##BPJ!~!JJJYGPG&&5!.                                   //
//                           ..         ^!        :~7~:~?PBPP5G#@@@&@&@@@@@@@@@@@&GJ^.::.?~~75^.                                   //
//                          :YG5J!.            :[email protected]#J. ^JP#@@B##?&@&@&[email protected]&G5&@@@@@BY~.  :  ::                                    //
//                           ^75B##J~:       [email protected]@B?. ^[email protected]@##J5B?.&@[email protected]@@YJ55BP5!G#B&&@#P7^                                          //
//                             :[email protected]#5!     :G&@&[email protected]@GGPY5PG :&@5&@@@[email protected]@#7                                          //
//                               :[email protected]#G!^  [email protected]@G?. [email protected]@GBPPP777. .&@[email protected]@@#?~:^.:~^[email protected]#Y~                                        //
//                                .?P&&B?:7&&&GY~^[email protected]@55YPJ~~:.. .&@P?BG&@#!         ^^~Y#B55:                                      //
//                   ...:^^:.      [email protected]#P5#[email protected]#[email protected]#BJGP5BB&&&B5J&@P.55#&@G             !B#YY~                                     //
//                :?G##&&@&##B57^.. ~5&@&#[email protected]#[email protected]@B&@@@@&#GY?7??&@P ?5P&@#~             :5BJ!.                                    //
//              :5B#PYYY5YYPBB#&#PP7:[email protected]@##&GJ:[email protected]@@@@&BP?:.     .#@G :75#&B^              :~Y^                                     //
//              !7^^ ...:...^7YB&@@&555&B&&[email protected]@@@BPY!:        .&@G  .JG#P~                ..                                     //
//                            :~J5G&@#[email protected]#B&@@@@#57^           :&@G   !&#?7                                                       //
//                   .:^~~!7!~^^!Y5G&@BP#&&@@@#GG?:             ^@@G   7GB~^                                                       //
//                ^JG#@&&@@&@@@&@&@&B&&[email protected]@@@BPGB#B###BBBB57:    [email protected]@P   ^^5.                                                        //
//             [email protected]@#B555YY5GB#&&BB##&@@@@@&B#BGGP5YJJJY55G#G~  [email protected]@P     .                                                         //
//            !#@BGJ?^:^:::~777!?5B#G&@@@#&B##GJ^          ^~^  [email protected]@5                                                               //
//           ^#B7^^..         [email protected]&YY&@[email protected]&#G&@&#?.             [email protected]@Y                                                               //
//           ^J:             ^B&#!:[email protected]@G5&[email protected]#?           .#@@J                                                               //
//                          :#&Y~ :&&J [email protected]~#@5  [email protected]?          ^@@@7                                                               //
//                         [email protected]:  .#B7 ^@@^5&P    .J#!         [email protected]@@~                                                               //
//                         [email protected]~    Y#^  [email protected]?.PB:     !!         [email protected]@@:                                                               //
//                         75:     .7.  [email protected] ^?.               .#@@#.                                                               //
//                         ..           ^@@! .                [email protected]@@G                                                                //
//                                       [email protected]                  [email protected]@@Y                                                                //
//                                       [email protected]@!                .#@@@7                                                                //
//                                       .#@B                [email protected]@@@^                                                                //
//                                        [email protected]@7               [email protected]@@#.                                                                //
//                                        .&@#.             [email protected]@@@5                                                                 //
//                                         [email protected]@J             [email protected]@@@7                                                                 //
//                                         .&@@^           [email protected]@@@&:                                                                 //
//                                          [email protected]@G           [email protected]@@@G                                                                  //
//                                          .#@@?         [email protected]@@@@7                                                                  //
//                                           [email protected]@&^       .#@@@@&:                                                                  //
//                                            [email protected]@B       [email protected]@@@@P                                                                   //
//                                            ^@@@Y     [email protected]@@@@@!                                                                   //
//                                             [email protected]@@!   [email protected]@@@@B                                                                    //
//                                             [email protected]@&^  [email protected]@@@@@!                                                                    //
//                                              [email protected]@@B [email protected]@@@@@P                                                                     //
//                                               [email protected]@@B&@@@@@@Y                                                                     //
//                                            .^7#@@@@@@@@@@@@P7:                                                                  //
//                                        .^7J5PGGGGGGGGGGGGGGGGPJ~                                                                //
//                                                                                                                                 //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ITR8N is ERC721Creator {
    constructor() ERC721Creator("Vapor Workstations", "ITR8N") {}
}