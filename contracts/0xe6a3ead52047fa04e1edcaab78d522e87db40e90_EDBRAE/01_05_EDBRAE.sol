// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                        :!?7.               //
//                                                                                   .:^7JYYY7.               //
//                                                                              .:^!?5PGGP5P5^                //
//          .:^!777???????????JJJJJJJJ??7!~^^:.            .:~!7??JJYYYYYYJJJJJYPPGGBBBGPPPP7.                //
//     :^7?Y5PGBBBBBBBBBBBBBBBBBBBB#########BGPYJ7!!!!!!7?YPBBBGGGGGB#&&&&&&&&&####BBBGGGPPJ.                 //
//    YPGGBBGBBBBBBBBBBBBBBBBBBBBB#B#BBBGGGP5YJ?777!77777JGBGP55555PGGB&&&&&&&&&&###BBBBGP7.                  //
//    GGBBBBBBBBBBB##BBBBBBBBBBB###BBBPY?!~^^::::::::::^!Y55Y5PPP5PPGBBB####&&&&&&&####BP~                    //
//    BBBBBBBBBBBBBBBB#BGBBBB###BBBBGY?!^:::::::::::::::!!?Y5GGGGPPPGB##########&&&####BG?.                   //
//    B#B####BBBBBBBBBBBBBGGGBBBBBGPJ7~^::::::::::::::::::7YPBBBBBGGGB############&&#####B5^                  //
//    B######B#B#BB##BGB#BBBBBBBBBPJ7~^^^^^^:^:::::::::::^~JPGGB#BBBBBB########&&&##&#####BY                  //
//    B######BB#BB#BBGGBBBBB#BBBG5?7~~~~~~~~~^^:::::::::^!!7PGGBBBB##BBB##########BBBBBGGBBP:                 //
//    BB###########BGGBBBB##BBBGPJ?!!!!!!!!!~^:::::^^^^~!!?YGBB##BBBBB##########BBGP55555PPG?                 //
//    B###########BBGGBBBBBBGBBPYJ77!7777!!!~^:::^^^~!!!!?YPB###################BBPYJJYJJJPB5.                //
//    B############BGBBBB#BGBBGP5J?77?777!!!~^::^~~!!777?YGBB###################BPYJJJJJPGGG?                 //
//    B###########BBGBBBB#BGBBGPYJ?????77!!!~^^^~~!!77?775B################B###BB5JJJJJ5#GYJ:                 //
//    ###########BBBBBBB##BB#BGG5YJ?????77!!~^^~~!!777?7!YBB##############BB###BBGYJYJJ5P5J~                  //
//    ###########BBBBB#B##BBBBGGP5YJJ????777!~~~!77????7!?5G##########BBGGPPPGGPPP5YYYY5YJJ:                  //
//    B###########BBBB#BB#BBBBBGG5YJJJ??77777!!!77??????77?YPB#BBBGGP5YJJJJJJJYYYY5YYYYYYJ~                   //
//    5B##########BBB##B####BBBBGPYYJJ??7777777777??????777??JYYJJJJJJJJYYYYJJJJJJYY555P5~                    //
//    ?YG#########B#B##BB###BBBBGPYJJ?????77777777??????????????????JJJ5GGGGGGG5YYYY5P5?^                     //
//    ??J5BB########B####BB#BBBBG5YJJ?????7???7777??????????????????JJJY5PGGGBGJ77~^:..                       //
//    ????J5G######BBB####B#BBBGP5YJJ??????????????????????????????JJJJJJJYPPP7                               //
//    ??????J5PBB##BBBB###BB#BGP55YJJJ???????????????????????????JJJJJJJJ?????.                               //
//    ????????JY5GB#BBB###BBBBGP5YJJJJJ?????????????????????????????JJ??J????^                                //
//    :7??????JJJY5GB#BB#BBBBGP5YJJJJJJ?????????????????????JJJJJJJJJJJJJJJJ~                                 //
//     .^?J???JJJJYY5GBBBBBBGP5YJJJJJJJ??????????J?JJJJJJJJJJJJJJJJJJJJJJJ7^                                  //
//       :7JJJJJJJJYYY5GBBBBGPYYYJJJJJJ?????????JJJJJJJJJJJJJJJJJJJJJJJJ?!.                                   //
//        :7JJJJJJJYYYY55PPGGGP5YYYYJJ???????JJJJJJJJJJJJJYJ?JJJJJJJJJJ??:                                    //
//         ^JJJJJYYYYYY????????????77J??????JJJJJJJJJJJJYJ!:..~Y555YYYJ??.                                    //
//         .7JJJYYYY55?.             ~?J?JJJJJJJJJJJJJJ?!:    .?55555YYJ?.                                    //
//          .!YYYYY555J.              ~JJJJJJJJJJJJJJ7^.       :J55555YJ?.                                    //
//           .~JYYY55557               7J?JJJJJJJJJJ!           :J5555YYJ:                                    //
//             ~YYYY5555^              :JJJJJJJJJJY?:            ^Y5555YJ^                                    //
//              !YYYY555Y!^.            ?JJJJJJJJYY7              ~5PP5YY?^.                                  //
//               ^J5YYYY5555!           :?JJJJJJJYY!              :YPPP5YYJ7!~:                               //
//                .!J55555PPY.           ^JJJJJJJYY?.              ~J5PPP55YYY^                               //
//                  .:^~^::.              7JJJJYYYYJ:                .:!?YPP?:                                //
//                                        ^JJJJYYYYJ.                     .:                                  //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract EDBRAE is ERC1155Creator {
    constructor() ERC1155Creator() {}
}