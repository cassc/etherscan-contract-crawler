// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Yuserx editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    .............::::::::::::::::^^^^^~~~^^^^~~~!!75##BGPBGGGGGGGGGGGGB#&&&&&&&&&&####B#&&&###              //
//    .............:::::::::::::::::^^^^^~~~^~~~~~!7JP#BB##BBGGGGGGGGGGGGGGB###&##&&&&####&&##                //
//    .............::::::::::::::::^^^^^^^~~~~~~~~~!5&&#GPBGGGGGGGGGGPPGGBBB#&&&#BBB##B#####                  //
//    ..............:::::::::::::::^^^^^^^~~~~~!!!!!!77?JGPYP#&&##BGGGGGGBBBBB#&&#&&&##BB##&&&&&              //
//    ............:::::::::::::::::^^^^^^^~~~!!!!~!!!!77JYJY55J?Y#&&&&&####BGGB#BBB##&&&&&&&&&&&&&&&          //
//    ..........:::^^:::::^^::::::^^^^^^^^~~^~!~~!!77??55?JJJYB#&&#########BBGGPGGB#&&&&&#&&&&&&&&            //
//    .......:::::^::::::::::^^^^^^^^^^^^^^^^^^^^~~~!77?JJ?!??YGPG&&##BBBB#BBBBBGBGGGGGPP#&&&&&#####          //
//    :.....:::::::::::::::^^^^^^^^^^^^^^^^^^^^^^^~^^^~!!!777??YPP#&#&&&#BBBBBPBBGBBBGY??JJJP#B#&&####        //
//    :::::::::::::::::::^^^^^^^^^^^^^^^::^^^^^^^^^^^??~^^~!!7JJ?JP##&##BBBGP5PGGPPGBJ7??777?YBBGBG#&#        //
//    .::::::::::::..:::::::^^^:::^^^^^^^^^^^^^::^^^7Y555J:^~!!!7P#&#BBBB#G??55PP5GY!!!!777?J?7??5##          //
//    :.:::::..........::::::::::::^^^^^^^^~^^::^~7?Y555555?^^^^^~?B#&#BBGG55J77!!7!~!!!?777!!?777JG          //
//    ...::........:....::::::::::::::::^^^^^^^~77?YY55Y5555Y?^:::^^?5P55GGPJ7!!^^~~!!!!!!77!77!!77?          //
//    :..:::............::::::::::::::::^^^^^^777?JYYYYYYY5555Y7^^^^~~!77!!^^^^^~!7!!!!!!!!77!!!!!            //
//    :.:::........................::::::::^!77??JYYYYYYYYYYY5555J!^^^^~~^^^^^^^^~~~!!!!!!!!77                //
//    ..:.:.................:..........:::!777??JYYYYYYYYYYYY555555J!^^^^^^^^^^^^^^^^~!!!!!!!!!!!777          //
//    :..:.............................:^!!777?JYYJJJJJYYYYY5YYYY5555?^::::^^^^^^^^^^^~~!!!!!!!7!!            //
//    ...:............................^~!!77??JJJJJJJJYYYYYYYYYYYYYYYY!:::^^^^^^^^^^^~~!!!~!!~!!!!            //
//    ..............................:^~!!!77??JJJJJJJJJJJJYYYYYYYYYYYYYY?^^^^^^^^^^^^^^~~!!!!!!!77            //
//    .............................:~!!7777?JJJJJJJJJJJJJJJJJJJJJJJYYYYYJJ:^^^^^^^^^^^^~~~!!~!                //
//    ............................:~!!7777?JJJJJJJJJJJJJJJJJJJJJJJJJJYYYJJJ!:^^^^^^^^^^^^~~~~~                //
//    ...........................:~!!!77??JJJJJJJJJJJJJJJJJJJJJJJJJJJYYYYYYJ:^^^^^^^^^^^~~~~~~                //
//    ...........................^~!!!7??JJJJJJJJJJJJJJJJJJJJJJJJJJYYJYYYYYYJ^^^^^^^^^^^~~~!~~                //
//    ..........................:!!!!77?JJJJJJJJYJJJJJJJJJJJJJJJJJYYJJJYYYYYYJ^^^^~~!!!!~~~^                  //
//    ..........................^!!!!!!7??JJJJJJJJJJJJJJJJJJJYYYYYYYYYYYYYYYYY57^^~~!!77!!~~~!                //
//    ..........................:!!77777?????JJJJJJJJJJYYYYYYYYYYYYYYYYYYYYYYYYJ^^~~!!!!!!!!!!!!!!            //
//    ..........................:!7777????????JJJJJJJJJJYYYYYYYYYYYYYYYYYYYYYYYJ^^^^~!!!~~!!!!!!!!!!!!        //
//    ...........................!77??????J?J?J?JJJJJJJJJJJJYYYYYYYYYYYYYYYYYYY?^^~^~!~~!!!!!!~!              //
//    ...........................???????JJJJJJ?JJJJJJJJJYYYYYYYYYYYYYYYYYYYYYY7^^^^^^~~~~!~~!!                //
//    ............................7????JJ?????JJ???JJJJJJJJYYYYYYYYYYYYYYYYYYYY^:^^^^^^~~~!~~~~!              //
//    .................. ........ :7????????????JJJJJJJJJJYYYYYYYYYYJJYYYYYYYY!:::^^^^^^^^^^^^~!^~^!          //
//    ............ ........... ... ^77??????????JJJJJJYYJJJJJYYJJJJJJYYYYYYYY!:::::^^::^^^^^^^^^^^^^^^~~      //
//    ............... ....... ..... :!??????????JJJJJJJYYYYYJYYJJJJYYYYYYYYJ!::::::::::::^^^^^^^^^^^!~        //
//    .............  .   ...   .. .. .^7?JJ??JJJJJJJJJJYYYYJJYYYYJJYYYYYYY?^...........:::^::^^^^^^^^!^^      //
//    ...............    . .    .      .^7JJJJJJJYJJJJJJYYYYYYYYYYYYYYY?7^................::::::^::^^^~^^^    //
//    ................          .   ....:~7??JJYJJJJJJJYYYYYYJYYYYYYJJJ!.....................:::^^^^^^^^^^    //
//    ........ .                    . .~777?7?JJJJJYYYYYYYYJJJJYYJJJ?7?J7^.....................:::::::::::    //
//    .........             .    ... :7????JJJ???JYYYYYYYYYJ?7JJJJ?????J7...:.   ...      ........::....      //
//    .........                .....^!77???J????JJYYYYYYYJYYJ?7JJJJ??7??J?!~. ..   .        . ............    //
//    ... ....                  .. :~7?7??J????JJYYYYY55YYYYJ?7JJJJ???????!7:   .  ..             ........    //
//    ......                  .   ..!?????????JJYYY5YY5YYYJYJ??YYYYJ?J???777~        .              ......    //
//    ..... .                 .   ..!?J?????JJJJYYYYYYYYYYYJJJYYYJJJ???JJ???7:.....  .                  ..    //
//    .....                       .^!?JJ????JJJYYYYYYYYYYYJ?JYYYYYYJJJ????J?~!^....                           //
//    ......                 ... .:!7JJJ??JJJYYYYYYY5YYYYYYJYYYYYYYJJJJ?J??J~:~....                           //
//    ...                       :~!7?JJJJJJYYYYYYYYY55YYYYYYYYYYYYYYJJJJJJJJ?^!. .                            //
//    ....                     :!77J?JJJYYYYYYYYYYYY5Y5YYYYYYYYYYYYYYYYYYJYJJ77:                              //
//    ..                      .~?JJJJJJJYYYYYYY5YYYYYYYYYYYYYYYYYYYYYYYYYYYJJJ?!:                             //
//    .. .                    :7JYYYYYYYYYYYYYYYYY5YYYYYYYJYYYYYYYYYYYYYYYYYJJJJ?^                            //
//           .               .~JYYYYYYYYYYYYYYYYYY5YYYYYYYYYJYYYYYYYYYJYYYYYYYJJJ?.                           //
//                          .^?YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJJJYYYYYYYYJJJJJJJJJ7:                          //
//                          ^7JYYYYYYYYYYYYYY5YYYYYYY55YYYYYYYJJYYYYYYYYJJJJJJJJJJJ7:                         //
//      .       .           ~JYYYYYYYYYYYYYYYYYY55555YYYYYYYYJJJJJJJJYJJJJYJJJJJJJJJ7:.                       //
//         .               .7YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJJJYJJJJJJJYYYJJJJJJJJJJ7^.                      //
//     ...         ..     :!JYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJJJYYYJJJJJYJYJJJJJJJJJJJ?~.                     //
//    .                  :~7JYJYYYYYJYYYYYYYYYYYYYYYYYYYYYYJYJJJJJJJJJJJJJJJJJJJJJJJ???7^.                    //
//                      :~7JJYJJJJJJJJJJYYYYJJYYJYJYYYYYYJJJJJJJJJJJJJJJJJJJJJJJJJJJJ???7:                    //
//                     .^!?JJJJJJJJJJJJYYJJJJJJJYYJJYYYYJJJJJJJJJJJJJJJYJJJJJJJJJJJJJJJ??!.                   //
//                     ^^7JJJJJJJJJJJJJYJJJJJJJJJJJYJJJJJJJJJJJJJYYJYJJJJJJJJJJJJJJJJJJ??7:                   //
//                    .^~???JJJJJJJJJJYYJJJJJJJJJJJYJJJJJJJJJJJJYYYYYYJJJYYJJJJJJJJJJJJ??7^                   //
//                    .^7??JJJJJJJJJJJJJJJJJJJJYYYJJJJJJJJJJJJJJJJJYYYYJYYJJJJJJJJJJJJJJ?7^                   //
//                    .^???JJJJJJJJJJJJJJJJJJJJYYJJJJJJJJJJJJJJJJJJJJYJYYYYYYYYYJJYJJJJJ?7^                   //
//                    .^??JJJJJJJJJJJJJYJYJYYYYYYYJJYJJJJYYYYYJJJJJJJYJYYYYYYYYYYYYYJJJJJ?:                   //
//                    .^7?JJJJJJJJJJJYJYYYYYYYYYYYYYYYYJYYYYYYYYYYYYJYYYYYYYYYYYYYJJYYJJJ!.                   //
//                    .^7?JJJJJJJJYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJYJJJJYYYJJ^                    //
//                     :7JJJJJJJJYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJYYJJJJ!.                   //
//     ..              .~?JJJJJJYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJYYYYYYYJ?!. .  .              //
//                      ^JJJJJJYYYYYYYYYYYYYYYYYYYYYYYYYYYY55Y55555Y555YY5YYYYYYYYYYYYYJ!:..  ..              //
//         .            7JJJJJYYYYYYYYYYYYYYYYYYY5Y55YYYY55555555555555555Y55YYYYYYYYYYYJ~..    ..            //
//                 ..  :?JJJJJJYYYYYYYYYYYYYYYYYYYY555Y555555555555555555555555YYYYYYYYYJ?.     . .           //
//    .  ..        .. .7JJJJJJYJYJJYYYYYYYYYYYYYYYY55Y5Y5555555555555555555555555YYYYYYYJ?~                   //
//    ....         . .~JJJJJJJJJJJJYYJYYYJYYYYYYYYY55555555555555555P555555555555YYYYYYYYYJ^      ..          //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract YUSXe is ERC1155Creator {
    constructor() ERC1155Creator() {}
}