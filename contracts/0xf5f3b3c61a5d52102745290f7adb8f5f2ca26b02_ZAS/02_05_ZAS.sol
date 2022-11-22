// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Zas 1155
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//     :^!77777777!^:                                                                                         //
//                                          :!??7!~^:~~:^~!7??!^                                              //
//                                     .^!~7J7^.     !~     .^7J7~~:.                                         //
//                                .^75GB#PJ7:        ^^        :7J5BBPY7^                                     //
//                              !5B####&Y?!.         ^^          !?J#&###GY~                                  //
//                            7B###&@@@G?7.          ::           [email protected]@@&###G!                                //
//                           5&B&@@@@@@Y?~           ^~.          ^[email protected]@@@@@&B#Y                               //
//                          !&[email protected]@@@@@@@J?^          ~JJ?          ^?J&@@@@@@@BB:                              //
//                          YG&@@@@@@@@5?!          .^^:          [email protected]@@@@@@@&G^                              //
//                          [email protected]@@@@@@@@#J?^                      :??#@@@@@@@@&P.                              //
//                          ~G&@@@@@@@@@BJ?~                    ^[email protected]@@@@@@@@#5                               //
//                          .P#@@@@@@@@@@#Y?7^                :!?Y#@@@@@@@@@@B!                               //
//                           [email protected]@@@@@@@@@@@BY?7~^..       .:[email protected]@@@@@@@@@@&Y                                //
//                            [email protected]@#57!!?5#@@@#G5YJ?77!!77?JYPG&@@@@@@@@@@@@@5:                                //
//                            .Y#G~::::::^[email protected]@@@@@&##BBBB##&@@@@@@@@@@@@@@@@P^                                 //
//                             ^5~^^:...::^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B7                                  //
//                              5J?77!~^^^^^7#@@@@@@@@@@@@@@@@@@@@@@@@@@&&GJ^                                 //
//                             7PPPPPPPPPPPP5PBB###&&&&@@@@&&&####BBBGGGGGGJ                                  //
//                             ^GGBBBBBGGGGGGGGGGGGGGGGBBGGGGGGGGGGGGGBB#&#Y                                  //
//                        ...:^YG&&&###BBBBBBGGGGPPB####BBGGGGGGGPPPPPPPPPPG7                                 //
//                      [email protected]@@@@@@@@@@&&&&&&###BBBG~                                //
//                      J5YYJ5G&&@@Y~^^^:^:::...:^^^^J#@@@@@@@@@@@@@@@@@@@@@BY                                //
//                     ~^.   [email protected]@@@@G7^^^^^^^^::.:^^^^~J#@@@@@@@@@@@@@@@@@@@#P.                               //
//                     .:^~  ?G&@@@@@@B?^::^^^^:::::^^^^~J#@@@@@@@@@@@@@@@@@#P...                             //
//                 :^^^~~~^  :[email protected]@@@@@@@#Y~:^^~^^:::::^^^^~Y&@@@@@@@@@@@@@#GJ7^^~~^^.                         //
//                !^...       [email protected]@@@@@@@@@BY7~^^^^:::::^^^^~5&@@@@@@@&GJ~:..::^^^^~!~.                       //
//                ::           !BB&@@@@@@@@@@@#5?!^^^:::::^^^^!P&&BGY7^.....::::^^^^~!~                       //
//                 .^^^::..     :YB#&@@@@@@@@@@@@&GY7^:::::::^^^!J7^........:::::^^^^~~                       //
//                    .:::^~^   .!B&####&&@@@@@@@@@@@#57^::::::^^^!?~:::::.....:::^^^~.                       //
//              ... .~:::.... :75PGGBB##########&&&&&&@&GJ!~^::::^^~77~^~~:.......:~?~.                       //
//            .:::...^^^^^^^!YPP555555PPGGGGGP5YJY555555555?~^^::::^^~7!~^^~:...:~YGBGGPY7~^.                 //
//           :~^::.......::^!7JJJ??Y5555Y?7~^::...::^^^^^^:^^^^~^^::^^^:::^^!!!JPBBBGB&&BGGGP5J7~^.           //
//          :~^:::.........      .:!7~^^:::::::::::::::::^^^^^^^^~~::::::::::^7PBBB#&&#GPPPPPGGGGGGY~.        //
//          :~^::...............:..^7::^^~~!!77??77!!!~~~~~~~~~!!7YY!:....:....:75GPB##BBBGPPPPPP5! ~:        //
//           ^~^::.     ...........^JJ5PGBB##########BBBGGBBGGBBBBBBGY!:.........:^^^~7JYPGBBBGP?. 7G.        //
//            .:^^!?77??~^~?J?7!~^^7PP555Y555PPPPPPGGGPPPPGGPPPGGGBGGGGJ^..........:::::::^[email protected]: [email protected]&.        //
//                [email protected]@@@@&G5YJY5PGGPGP5YYYYYYYYYYYYY55555555YYYYY555PPPPP5!::...........^?!?#B! ^[email protected]@@&:        //
//                [email protected]@@@@@@@@&#G5YJY5PGGGPP5555555PPGGGGGGPPP5YYYYYYYYY5G##7::.:::^^^^~!?P#&? :Y&@@@@@^        //
//                [email protected]@@@@@@@@@@@@@@#G5YJY5PGGGPPGGBB######BBBBBGP55Y55G#&#J^:::^^^^^~!!?B&Y..J#@@@@@@B.        //
//                YB#@@@@@@@@@@@@@@@@@@#GPYYY5PGBGGBBB########BBGPPG#@&BP5J!~:::....~5&P: [email protected]@@@@@@J.         //
//                 !YG#&&@@@@@@@@@@@@@@@@@@@&BPYYY5PGBBBB#####BBBB#&#BGPGGGGGPP5J7!J&G~ [email protected]@@@@@@G^           //
//                   .^7JPG#&&@@@@@@@@@@@@@@@@@@@&BP5YYY5GB#BBBB###GPGGGGGPGGGGGBB#B! [email protected]@@@@@@#7             //
//                        :~7YP##5P#@@@@@@@@@@@@@@@@@@&BP5YYGPGBBGPPPPPPPPPGGGGGBP! :5&@@@@@@@Y.              //
//                            .:.  .^!JP#@@@@@@@@@@@@@@@@@@&PJ5Y5555PPPPPPPPPGBG?.:J&@@@@@@@B~                //
//                                      .^!JP#@@@@@@@@@@@@@@#[email protected]&#BGP5555PPPPGGJ:.?#@@@@@@@&?                  //
//                                           .:!JP#&@@@@@@@@@&@@@@@&###BGPPPP!:[email protected]@@@@@@@5:                   //
//                                                 :!JPB&@@@@@@@#&&[email protected]@&#PB&@@@@@@@@B!                     //
//                                                      :[email protected]@&##@@@[email protected]@[email protected]@@@@@@@&J.                      //
//                                                           [email protected]@5.7#@@G:Y?&@[email protected]@@@@@@P^                        //
//                                                            J#@7 :#@@^7G&@[email protected]@@@@#7                          //
//                                                             .~?~:[email protected]@[email protected]@@@[email protected]@@@Y.                           //
//                                                                ..:^7YPB&@[email protected]@G^                             //
//                                                                        :^~!^                               //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ZAS is ERC1155Creator {
    constructor() ERC1155Creator() {}
}