// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: C-Dub
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                       ..::^^~~~~!!!!!!!!!~~~~^^::::.                                       //
//                                  .:^~!!!!!!!!!!!!!!!!!!!!!!!!!!!7?YJJ?!~:.                                 //
//                             .:^~!7777777!!!!!!!!!!!!!!!!!!!!77?J5PPPPPPP5Y?!^.                             //
//                          .^~!77777777777!!!!!!!!!!!!!!!!!7JJYPPGGPPP555555555J7~.                          //
//                       .^!777777777777777!!!!!!!!!!!!!!!!J5PGGPPPPP5555YYYYYYYYYYJ7^.                       //
//                     :!7777777777777777777!!!!!!!!!!!!7YPGPPPPPPP55555555YYYYYYYYYYY?~:                     //
//                  .^7?77777777777777777777!!!!!!!!!!!?PBG55555PPPGGBB####BBGPP5555555YJ7^.                  //
//                .~7?77777777777777777777777!!!!!!!!!YBBG5555PGB##&&###BGGGBBB####BP5PGG5YJ!.                //
//               ^7??777777777777777777777!!7!!!!!!!75BBG555PB#####BBBBGGGBBGBGG##&#GP55PPYJJ5~               //
//             :7??7777777777777777777777!!!!!!!!!!!5BGPPPPB&#BB##BBBBB###&###&#GPPBB##GGGP5JYG7.             //
//            ~??7777777777777777777777!!!~!!!!!!!!7PGPPPP##BBB#BBB######&&&###BPP5YYYP###BB5Y5Y!^            //
//          .!????77777777777777777777!!!!!!!!!!!!!7GGGGGB#PPGBBBBB##########BPPPPPGPPYB####P5PJ!!~.          //
//         :7?????777777777777777777!!!777!!!!!!!!!!5BGGG#BP5PPGGGGGBBBBBGGPGPPB#BGGB#PPGGGPGPY?!!!!.         //
//        :7??????????77777777777777!!!7777777!!!!!!YGGG##BP55555PPPPPPP555PPGBBGP55PGPY555YY7!!!!!!!:        //
//       :7?????????7?77777777777777777777777777!!!!JGB##BP555555PPPPPP555555P555YYYYJ?JYJ???7!!!!!!!!.       //
//      .7????????????7777777777777777777777777777!!7PGBGP5P555PPPPPP555555555PPPPPPP55Y?JJ???!!!!!!!!~.      //
//      !???????????7777777777777777777777777777777!YGPP55PP555PPPPPP5555555PGGPPPPPP5555JJJJJ!!!!!!!!!^      //
//     :????????????7777?7777777777777777777777777!7GGPP55PP55PPPPPPP5555PPPPPPPPGGPPGP5YYJ?JJ7!!!!!!!!!:     //
//     !????77?7?????7????777777777777777777777777!7PPPGP5PP5PPPPPPPP55Y555555PPP5YYYJY55YJJ?J7!!!!!!!!!~     //
//    :7777?7?????77?7??7?7777777777777777777777777!JPGPPPPPPPPPPPPPP55555555555555YYYJJJYJJJJ?~!!!!!!!!!.    //
//    ~?77?7777??7???7?????777777!!77777777777777777!?YYPGG5PPPPPPPPPPPP5555555555P5YYJJ??JJJY?~!!!!!!!!!^    //
//    7?7??777?7??????????77?77~:.^!77777777777777777!!!7YP55PPPPPPPPPPPPPPPPPPPGGPPP5555YJJYY7!!!!!!!~~!!    //
//    7???7???????????????7777!:. ....^!777777777777777!!!JPPPPPPPPPPPPPPPPPPPGGGGGBBBBGGPPPY7~!!!!!!!~~~~    //
//    7????????????????????7777^.      .^77777777777777!!!!?PGPPPGPGGGGGGGGGGGBBBBBBBBBBBGP?!~!!!!!~~~~~~!    //
//    7????77????????????????77~:..     .~77777777777777!!!!?PGGGPPGGPGGBBBBGGBB######BBGPJ!~!!!~~~~~~~~~!    //
//    7??7?777777~!!~^~~^^~~^:^:........ .^^^~!777777777!!!!!JGPPPPGGGGGGBBBGGBB###BBBGP5YJ7~!~~~~~~~~~~~^    //
//    ~?7???7!^^:::..        ...  .  ....    .:~77777777!!!!!!YPPPGGGGGGGGGGGGBBB#BBBP5YYYJJ!~~~~~~~~~~~~^    //
//    :7777~~~~~:...                           .!7777777!!!!!!?PPPGGGGGPPPPPPGGGGGBGPYYYYYYJ?!~~~~~~~~~~~.    //
//     ~7^:.......                              :!77777!!!!!!!7PPPPGGGGGPPPPGGGGPGGGP55Y5YYYY5J7!!~~~~~~^     //
//     :~^^^::......           ..............    :^~!!!!!!!!!!7PGPGGGGGGGGGGGGGGGGGGPP5555YYJ5GGPP555YY5^     //
//      ^~^:::::::.......   ............::::::::..:^~!!!!!!!!!JGGGGGGGGGGGGGGGGGGGGGPP55555YYY5GGGGGGGBY      //
//      .~^::::::::........:..:..........:^^~!~~^^^^!!!!!!!!!?GGGGGGGGGGGGGGGGGGGGGPPP555YY55YYYPGGBBBP:      //
//       .!!~^^^^^^^^^^^^^~~^^^^^:::.::...^~~!!!!!!!!!!!!!!!YGGGGGGGGGGGPPPPPGGGGGGPPPP555555YYYY5GGBG^       //
//        :77777777777777777!~~!7!!~~~!~^^^~~~!!!!!!!!!!!7YPGGGGGGGGGGGGGGPPPPGGGGGPPGP555Y555YY55PGG~        //
//         :!777777777777777777777777777!!!!!!!!!!!!!!?J5GGGGGGGGPPGGGGGGGGP55GGGGGGGGP55YY5555PPPGP^         //
//          .!77777777777777777777777!!!!!!!!~~~!!7J5PGGGGGGGGGGPPPGGGPPGGGP555PGGGGGGP55YY555PPGGY:          //
//            ^77777777777777777!!!!!77?JJJ???JY5PGGGGGGGGGGGGGGGPPGPPPPPGGP5YY55PPPPGP555Y55PPGG?.           //
//             :!77!!!!!!!!!!!!!7?JY55PPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPPPPP5YYY55PPGGPP5555PPG5^             //
//               ^!7!!!!!!!!!7?YPPPPPGGGGGGGGGGGGGGGGGGGPPPGGGGGPPPPPPPPPPP5YYYYY5PPGGPPPPPPGP7.              //
//                .^!!!!!!!7J5PPPPPGGGGGGGGGGGGGGGGGGGGPPPPPPPPPPPPPPPPPPPPP5PP5YY5PPPPPPPGP7.                //
//                  .^~!!7YPPPPPPPPGGGGGPPPGGGGPGPGGGGGGPPPPPPPPPPPPPPGPGPPPPPPPP5PPPPPGG57.                  //
//                     :7PGGPPPPPPPPPPPPPPPPPPPPPPPPPGPPPPPPPPPPPPPGGGGPPPPPP5PPPPPPPGPJ~.                    //
//                       :!YPPGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGGGGGPPPPPPP5PPPPPPY!:                       //
//                          :!J5PPPPPPPPPPPPPPPPPPPPPPPGGPGPPPPPGGGGGGGPGPPPPGPP5J!:                          //
//                             .^!J5PPPPPPPPPPPPPPPPPPPGPPGPPPGPPGGGGGGGGGGP5J7^.                             //
//                                 .:~7?Y5PPGGGPPPPGGGGGGGGGGGGGGGGGGP5YJ7~:.                                 //
//                                       .:^!7?JY55PPPGGGPPPPP5YY?7!~:.                                       //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CDUB is ERC721Creator {
    constructor() ERC721Creator("C-Dub", "CDUB") {}
}