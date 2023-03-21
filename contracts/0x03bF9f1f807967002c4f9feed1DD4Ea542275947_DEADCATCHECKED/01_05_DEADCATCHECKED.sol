// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dead Cat Check Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                            :!?:                                            //
//                                              .^!777777??7JG&@Y                                             //
//                                          .^7YG#&&&&&@@@@@@@@#:                                             //
//                                     .:~7YPB&&&@@@@&&@@@@@@@@5                                              //
//                               .:^!7JY5PB##&&@@@@@@@@@@&#G55P?.                                             //
//                           .!?J55PPPPGB##&&@@@@@@@@&BPY?7~^^^~~:.                                           //
//                          ^5GGGGGGGBB##&&@@@@@@&#G5J7!~^.      ..                                           //
//                        .?GBBBBBB##&&&&@@@@@&BPY?7!^..                                                      //
//                       :5B#####&&&@@@@@@&@&BPJ7~:.                                                          //
//                      ^5B###&&&@@@@@@@@&@#BY!:           .:       .                                         //
//                     !PGB###&&&@@@@@@@@@BP?:          .J5&&5Y:  ....                                        //
//                    7PGGB####&&@@@@@@@@B5J~. :!GG7~  :[email protected]@#[email protected]#!.:::                                         //
//                  .?PPGB#####&&@@@@@@@@#Y?^ ~&@@[email protected] .J&#[email protected]@P^:^^.                                         //
//                 .?5PPGB####&&@@@@@@@@@&P?^:[email protected]?~#@B:  ~?5#P7^:^:                                           //
//                 ?55PGBB###&&&&&@@@@@@@@BJ^.:[email protected]#P:      .:::.                                             //
//                !55PPGBB###&&&&@@@@@@@@@&Y^. ..~7:   ^!   ..                                                //
//               :Y5PPGGBB###&&&&@@@@@@@@@@P~....   .. P#: .:.                                                //
//              .J55PPGGBB##&&&&@@@@@@@@@@@#[email protected]@J .^:                                                //
//              755PPPGGBB##&&&&@@@@@@@@@@@&5~:::[email protected]@#::~^                                                //
//             ^555PPPGGGBB##&&&@@@@@@@@@@@@G7~^::::::7??7.^~~                                                //
//             ~555PPPGGGBB###&&@@@@@@@@@@@@&Y7~^:::::.....^~~.                                               //
//             ^5555PPPGGBBB##&&&@@@@@@@@@@@@GJ7!~^^^::.::^^~!.                        ^                      //
//             .J5555PPPGGBB###&&@@@@@@@@@@@@@PYJJ?!!~J7:^!57!.    .:                .JB~                     //
//              755555PPPGGGB##&&&@@&@@@@@@@@@&P5PBYJJP#7!?&P7.    !BY~             ^5&@P:                    //
//              ^Y55555PPPPPP5J7!!7PBB&@@@@@@@@#PP##PPG&GJ755~     [email protected]&#Y^         :7G&@@@7                    //
//              .JYY55YY55J!:      J#&@@@@@@@@@@##&&&&##?.        [email protected]&&&GY7?JJYYYYP#&@@@@J                    //
//               !YYYYYYY5~        Y#&@@@@@@@@@@@@@@@@&#!         !&@@&&&#BBBBBBB##&@@@@@G^                   //
//                ^7YYYYYY^       .P&&@@@@@@@@@@@@@@@@&#?        ^[email protected]@@@@&&#######&&@@@@@@&P7:                 //
//                  :7JYYY^       :B&&@@@@@@@@@@@@@@@@&#?       ~5#@@@@@@&@@@&&&@@@@@@@@@@#BP~                //
//                    :!?Y~       ~#&&@@@@@@@@@@@@@&&&&#J      !G#&@@@&B?:75#@@@@5J^[email protected]@@@&&B:               //
//                      .~7.      ?&&@@@@@@@@@@@&@&&&&&#Y.    :[email protected]@@@@@?  :7 ~#@&? ..Y^ [email protected]@@@@@?               //
//                               .5&&@@@@@@@@&&&&@@&&&&#P:    !#@@@@@#^.?Y^ ~#@&Y:~J! [email protected]@@@@@5.              //
//                               ^[email protected]@@@@@@@@@&&&@&&&&&&#G^    7&@@@@@@@Y?:~5#@@@@B5?~Y#@@@@@@@?               //
//                               ~#@@@@@@@@@&&&&&&&&&&##B!    [email protected]@@@@@@@@&@@@@@@@@@@@@@@@@@@@5:               //
//                               ?&@@@@@@@@@&&&&&&&&&&#BB?    .?#@@@@@@@@@@@@@@@@@@@@@@@@@@&Y:                //
//                              [email protected]@@@@@@@@@&&&&&&&&&&#BBY.    .7G&@@@@@@@@@@@@@@@@@@@@&&#P!.                 //
//                              :B&&&@@@@@@&&&&&&&&&&##BB5:      :!YGB&@@@@@@@@@@@@@&#PJ7~.                   //
//                              !#&&&&&@&&&&&&&&&&&&&##BGP^         .:[email protected]@@@@@@@@@@&&&P.                       //
//                              J###&&&&&&&&&&&&&&&&&##BGG!           J&@@@@@@@@@&&&#G^                       //
//                             .P####&&&&&&&&&&&&&&&&##BGG?           Y&@@@@@@&&&&###B7                       //
//                             ^B#####&#&&&&&&&&&&&&&##BGGY.          [email protected]@@@@@&&&&##BBBY                       //
//                             7BBB########&&&&&&&&&&##BBG5:         [email protected]&@@@&&####BBGG5.                      //
//                             JBBBBB#########&&&&&&&##BBBP~         ^B&&&@&&#BBBBBGPGP:                      //
//                            .5GBBBBBB#########&&&&&##BBGG!         !#&&&&&##BGGGGPPPP~                      //
//                            ^PGGGGGBBBB##############BBGG?         ?#&&&&&#BGGGPPPP5P!                      //
//                            ~PGGPGGBBBBBB#############BGGJ.        5#&#&&#BBGPP5P5Y55?                      //
//                            !PGGGGGGBBBBBBBBBBBB####B#BGGP:       .G###&##BGPPPPP5555?                      //
//                            7PGGGGGGGBBBBBBBBBBBBBBBBBBGGG~       :GBB###BGGPPPP5555YJ.                     //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DEADCATCHECKED is ERC1155Creator {
    constructor() ERC1155Creator("Dead Cat Check Editions", "DEADCATCHECKED") {}
}