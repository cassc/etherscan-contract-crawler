// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pocket Poko
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ooooooooo.                       oooo                      .                                            //
//    `888   `Y88.                     `888                    .o8                                            //
//     888   .d88'  .ooooo.   .ooooo.   888  oooo   .ooooo.  .o888oo                                          //
//     888ooo88P'  d88' `88b d88' `"Y8  888 .8P'   d88' `88b   888                                            //
//     888         888   888 888        888888.    888ooo888   888                                            //
//     888         888   888 888   .o8  888 `88b.  888    .o   888 .                                          //
//    o888o        `Y8bod8P' `Y8bod8P' o888o o888o `Y8bod8P'   "888"                                          //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//    ooooooooo.             oooo                                                                             //
//    `888   `Y88.           `888                                                                             //
//     888   .d88'  .ooooo.   888  oooo   .ooooo.                                                             //
//     888ooo88P'  d88' `88b  888 .8P'   d88' `88b                                                            //
//     888         888   888  888888.    888   888                                                            //
//     888         888   888  888 `88b.  888   888                                                            //
//    o888o        `Y8bod8P' o888o o888o `Y8bod8P'                                                            //
//                                                .:^^::.                                                     //
//                                            ^7J5PGBBBGP5J!:                                                 //
//                                          ~P##############B5!                                               //
//                                         :B&#5B&&P5&#B&&&&&&&G^                                             //
//                                         !GPJ??PBYJ5J?55PPG&&&B:                                            //
//                                         ^?JJJJJJJJJJJJ??JYG&&&P                                            //
//                                          7??J?JJJJJJJJJJ5GP&&&&~                                           //
//                                          ~77??Y55J???????J5PPB&P                                           //
//                                          ^7??JPGPYJ?JJJJJJJJJP&&~                                          //
//                                          :?YJ????JJJJJYYYY5PB&&&G:                                         //
//                                           ^BG5YYYYYY5555P#&&&&&&&P                                         //
//                                            5&#BPPPPPPPPP#&&&&&&&&&?                                        //
//                                            Y&&&#PPP55555B#B#&&&&&&#^                                       //
//                                            J&#GG5Y5YYY5J?7Y55JJ5PB#B^                                      //
//                                          :~??7???JJJJYJ7!7Y?!^^^:^~JB!                                     //
//                                         !J?~~JJ??????7?JJ7!!~!7!!::^7G7                                    //
//                                      .^!YY7~!?7777?7~!YJ7!!7?JY55!^:^!P?                                   //
//                                      !!7J?!~7J777?7~~77~~~!7JYYPGP7^:^!P?                                  //
//                                     ^!~?J!^^75PP5J~77^^^~!?J555PPBP7^^^~57                                 //
//                                    .!~???Y7^!YGGPJ!Y~:^~7?Y5PPPPPBBP?~^^~7.                                //
//                                    ~!^JY?7J?7JGBBY?5!~!7JY55PPPPPBBBGY!^^~!.                               //
//                                   :!^:!YJ?7?JJPGBGYP7~!7?Y55PPPPG&&BBB57^:^~:.                             //
//                                  .!^^^75G5J?7!?5GGPY~^^!7?J5PPPPB&&&#BBGY!~^^~^:                           //
//                                  ~~^^!YGBGYJ7~:7PGG?^::^!7JY5PPG&&&&&&GGBBPY7~^^^:.                        //
//                                 :!^^!JGBB7:??!^^JPGJ^::^!?J5PPP#&&&&&@?.~JGBBPY7~^^^:                      //
//                               :~~^~7YPGP!  ~J7~^JPGJ!!7?JY5PGGP5#&&&#J    .^?5GBPY7^^^:                    //
//                            .:~~^~?5GBGJ:   ?P555PPPPPPPPPPPPGG5 ?&&G^         :~JPGPYJ?!~~^^:.             //
//                           :~~~!JPGBGY~    ^Y55555YYYYYYYYYYYY5Y:.BG.              ^7J??JJJJ?J?!!~~^^.      //
//                         :~~~7YPBBG?:    ~?Y5PPPPPPP5555YYJJJJ?7! :.                   .~7JJJJJ??7!^:       //
//                       ^!!!7YGBGY!: .   [email protected]&&&&&&&&&&&&&&&&&##BG5J!                        ^7??!7^.:^:       //
//                 .^^~~!JJY5GG5?7J5GBB5?!YB&&&&&&&&&&&&&&&&&&&&&&&&J                         .!~.^^          //
//        ..:::^~7?JJYYYYYY?J??YG&&&&&&&&BJ?YG&&&&&&&&&&&&&&&&&&&&&&B.                          :             //
//      .~~~~!?YYJYYYYYYJ!~!5B&&&&&&&&&&&&#YYY5G#&&&&&&&&&&&&&&&&&&&#:                                        //
//        .:~!!~!JJJYJ7~.Y#&&&&&&&&&&&&&&&&GYY555PG#&&&&&&&&&&&&&&&&B.                                        //
//        :^:..~!^!?~.  [email protected]&&&&&&&&&&&&&&&&&BY555555#&PG#&&&&&&&&&&&@?                                         //
//            ^: ^7.    :G&&&&&&&&&&&&&&&&#BY555555#P?JYY5PG#&&&&&&G                                          //
//               .       :P&&&&&&&&&&&&&&#P555555P&#JJJJ?????JYG&&&~                                          //
//                         !G&&&&&&&&&&#J7??77JGBBGY?JJ?????????YBJ                                           //
//                           7B&&&&&&&&&Y      ::..75GBGP5YJ?????~                                            //
//                            .?#&&&&&&&&J        ^#&&&B##&##GJ?!                                             //
//                              :Y#&&&&&&#!       [email protected]&&#GB#&&&&&J                                              //
//                                ^5&&&&&&#?^     G&&&&&&&&&&&B:                                              //
//                                  !&&&&&&@&Y   ^&&&&&&&&&&&B:                                               //
//                                   ~#&&&&&&&~  J&&&&&&&&&&B^                                                //
//                                    [email protected]&&&&&GG: G&&&&&&&&&#^                                                 //
//                                    .#&&&&&J!!:#&&&&&&&&&7                                                  //
//                                     Y&&&&&#^ ?&&&&&&&&&Y                                                   //
//                                    .#&&&&&&^ G&&&&&&&&&^                                                   //
//                                    .P#&&&&@!^&&&&&&&&&B.                                                   //
//                                      .JGB#5 ?&&&&&&&&&P                                                    //
//                                        .::  Y&&&&&&&&&?                                                    //
//                                             5&&&&&&&&&^                                                    //
//                                             G&&&&&&&&B.                                                    //
//                                            :#&&&&&&&&Y                                                     //
//                                            ~&&&&&&&&@!                                                     //
//                                            :&&&&&&&&#:                                                     //
//                                            .B&&&&&&@P                                                      //
//                                             [email protected]&&&&&@J                                                      //
//                                             [email protected]&&&&&&~                                                      //
//                                             [email protected]&&&&&B.                                                      //
//                                             [email protected]&&&&@Y                                                       //
//                                             [email protected]&&&&@?                                                       //
//                                             ?#BBBB#!                                                       //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PPoko is ERC1155Creator {
    constructor() ERC1155Creator("Pocket Poko", "PPoko") {}
}