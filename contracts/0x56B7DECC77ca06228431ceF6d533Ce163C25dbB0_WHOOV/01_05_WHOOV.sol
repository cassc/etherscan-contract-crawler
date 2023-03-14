// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TheWhoove
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//               ______  __              __      __  __                                                       //
//              /\__  _\/\ \            /\ \  __/\ \/\ \                                                      //
//              \/_/\ \/\ \ \___      __\ \ \/\ \ \ \ \ \___     ___     ___   __  __     __                  //
//                 \ \ \ \ \  _ `\  /'__`\ \ \ \ \ \ \ \  _ `\  / __`\  / __`\/\ \/\ \  /'__`\                //
//                  \ \ \ \ \ \ \ \/\  __/\ \ \_/ \_\ \ \ \ \ \/\ \L\ \/\ \L\ \ \ \_/ |/\  __/                //
//                   \ \_\ \ \_\ \_\ \____\\ `\___x___/\ \_\ \_\ \____/\ \____/\ \___/ \ \____\               //
//                    \/_/  \/_/\/_/\/____/ '\/__//__/  \/_/\/_/\/___/  \/___/  \/__/   \/____/               //
//                                                                                                            //
//    5P5JJJJ?JYJJ????JJJJJJJJJJJJJJ?JJJJJJJJJJJJJJJJJJJJJJJJJ????????JJJJJJJJJJJJJJJJ????J???????????????    //
//    5P5JJJJYYJYYJ???JJ??JJJJJJJJJJJJJJJJJJ?JJJJJJJJJJ???JJJJ??????77777777??????????7??????777??????????    //
//    PP5JJJJYJ??YP5J?????JJJJJYYYYYJJJJYJG#B###########BB#####BB###BBBBBBP7?7??7???7777?????7!77???JJJJJJ    //
//    PP5JJJJJJJ?7JPPYJJJJJJJJYYYYYYJJJJJJG&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&G77777???777777????7!!7???JJJJJJ    //
//    PPYYJYYJJJJ???JJYYYYJJJJYYYYYYJYBBBB#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#GGBBJ7?7777777????7!!7???JJJJJJ    //
//    PPJJYY5YJ?????777!!!??JJJYYYYYJY&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&J7777?7777???77!77?????????    //
//    PPJJJYG5J?!!777!!!!!??JJJYYPGGGB&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&GPPP577!77??777!77JJJJJJJJJ    //
//    5PJJJJP5J?!!!777!!!7??JJJYJB&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@B77!!7?7777!77JJJJJJJJJ    //
//    55JJJJPPJ?7!!777!!!7??YPPPP#&&&&&&&&&&&&&&&&&&&&&&BGGGB&&&&&&&&&&&&&&&&&&&&&&&B7Y5?77777!77JJJJJJJJJ    //
//    55JJJJ5PY?777777!!!7??5&&&&&&&&&&&&&&&&&&&&&&&&&&@Y^^^[email protected]&&&&&&&&&&&&&&&&&&&&&&&&&@Y!77?7!77JJJJJJJJJ    //
//    PPJJJJ5PY?7!!7777777??5&&&&&&&&&&&&&&&&&&#BBBB#BB#J^^^J#####BB##&&&&&&&&&&&&&&&&&&J!7??7!77JJJJJJJJJ    //
//    5PYJJY5P5?777777!7!7??5&&&&&&&&&&&&&&&&&&J^~~~~~~~~^^^~~~~~~~~^J&&&&&&&&&&&&&&&&&&J!???7!77JJJJJJJJJ    //
//    5PJJJJY5PJ7!!777!777??5&&&&&&&&&########&?^^^^^^^^^^^^^^^^^^^^^?&########&&&&&&&&&J7???7!77JJJJJJJJJ    //
//    5PJJJJYYPY!!!777!!77??5&&&&&@@@#!!!!!!!!!~^^^^^^^^^^^^^^^^^^^^^[email protected]@@&&&&&J7???7!77JJJJJJJJJ    //
//    5PJJJJYY557!!777!!!7??5&&&&&@@@B^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^[email protected]@@&&&&&J????7!77JJJJJJJJJ    //
//    5PJJJJYYYP7!!777!!!7?J5&&&&&@@@B^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^[email protected]@@&&&&&Y????7!77JJJJJJJJJ    //
//    5PJJJJ5YJ5?!!777!!!7?J5&&&&&@@@#[email protected]@@&&&&&Y????7!77JJJJJJJJJ    //
//    55JJJJYYJ5Y!!777!!!7JJYPPP5#@@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@#YYYY?????7!77JJJJJJJJJ    //
//    55JJJJYYJJ57!777!!!!JJJJJJ?#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B77!!7????7!77JJJJJJJJJ    //
//    5PJJJJ5YJJ5?!777!!!7YJY##B#[email protected]@@#[email protected]@@&????&@@@G~!!!!????#@@@B77!77????7!77JJJJJJJJJ    //
//    [email protected]@@@7^^^^^^^:[email protected]@@#     :::[email protected]@@&~^^^#@@@5     ::::[email protected]@@B77!7?????7!77JJJJJJJJJ    //
//    [email protected]@@@?^^^^^^^^[email protected]@@#[email protected]@@&~^^~#@@@G!7777JJJ?#@@@B77!!?????7!77JJJJJJJJJ    //
//    [email protected]@@@?^^^^^^^^[email protected]@@@@@@@@@@@@@@@@&~^^~&@@@@@@@@@@@@@@@@@B77!7?????7!77JJJJJJJJJ    //
//    [email protected]@@@Y7777^^^^5BBBBBBBBBBBBBBBBBG~^^~GBBBBBBBBBBBBB&@@@B77!7?????7!77JJJJJJJJJ    //
//    [email protected]@@@@@@@B^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^[email protected]@@B77!7?????7!77JJJJJJJJJ    //
//    5PJJJJ5YJ?!75J!7!755YJ5&&&&@@@@#7777!^^^^^^^^^^^^^^^^^!?????????~^^^^^^^^[email protected]@@B77!7?????7!77JJJJJJJJJ    //
//    5PJJJJ5YJ?7!JY77!?P5YJJJJJJ#@@@&GGGBP^^^^^^^^^^^^^^^^^[email protected]@@@@@@@@!^^^^^^^^[email protected]@@B77!7?????7!77JJJJJJJJJ    //
//    5PJJJJ5YJ?7!?57!!YP5YJJJJJJ#@@@&GGGGP!!!!~^^^^^^^^^^^^[email protected]&&&&&&&&!^^^!!!!!#@@@B77!7?????7!77JJJJJJJJJ    //
//    5PJJJJ5YJ?7!75J!75P5YJJJJJJ#@@@&GGGGGGGGB7^^^^^^^^^^^^~!!!!!!!!!^^^^5GGGG&@@@B77!7?????7!77JJJJJJJJJ    //
//    5PJJJJ5YJ?7!!YY!?PP5YJJJJJJ#@@@&GGGGGGGGB?~~~~~~~~~~~~~~~~~~~~~~~~~~PBGGG&@@@B77!7?????7!77JJJJJJJJJ    //
//    5PJJJJ5YJ?7!!J57YPP5YJJJJJJ#@@@&GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG&@@@B77!7?????7!!7JJJJJJJJJ    //
//    5PJJJJ5YJ?7!!75J5PP5YJJJJJJ#@@@&GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG&@@@B77!7?????7!!7JJJJJJJJJ    //
//    5PJJJJYYJ?7!!7Y555P5Y?JJJJJ#@@@&GGGGGGGGGGGGGGGGGGYJYYYYYYYYYJYYGGGGGGGGG&@@@B7777?????7!!7JJJJJJJJJ    //
//    5PJJJJYYJ?7!!!JPPPP5J?JJJJJ#@@@&BBBBGGGGGGGGGGGGGGJ????????????JGGGGGGGGG&@@@B77777????7!!7JJJJJJJJJ    //
//    5PJJJJYYJ?7!!7?GPPP5J?JJJJJ#@@@#JJJJPGGGGGGGGGGGGG55555555555555GGGGGGGGG&@@@B77777????7!77JJJJJJJJJ    //
//    55JJJJYYJ?7!77?GG5P5??JJJJJ#@@@B^^^^YBBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG&@@@B77777????7!77JJJJJJJJJ    //
//    JY7????JJ?7!77YGGPPY??JJJJJ#@@@B^^^^?YYYYGGGGGGGGGGGGGGGGGGGGGGGGGGGB####BBGBP777777???7!77JJJJJJJJJ    //
//    JJ7??????7!!!75PGPPJ??JJJJY#@@@B^^^^^^^^~GBGBBGGGGGGGGGGGGGGGGGGGGGG#@@@@J7777??7777???7!77JJJJJJJJJ    //
//    JJ7??????7!~~75PGG5???JJJYY#@@@B^^^^^^^^~5555PBBBBBBBBBBBBBBBBBBBBBBB####J7?????7777???7!77JJJJJJJJJ    //
//    JJ7??????7!~~J55PG57??JJJYY#@@@B^^^^^^^^^^^^^[email protected]@@@@@@@@@@@@@@@@@@@@@G7777???????7777???7!77JJJJJJJJJ    //
//    JJ7??????7!~~Y555GJ!??JJYYY#@@@B^^^^^^^^^^^^^[email protected]@@@&&&&&&&&&&&&&&&&&&G7??????????7777??77!77JJJJJJJJJ    //
//    JJ7???????!~75555G5?JJJYYYJ#@@@B^^^^^^^^^^^^^[email protected]@@@P7JYYJ??????7?????????????????77777777!7?JJJJJJJJJ    //
//    JY7???????7!J555GGBGYYJJYYJ#@@@B^^^^^^^^^^^^^[email protected]@@@5!?JJ???????7777777???????????7777??JJ77?JJJYYYYJJ    //
//    JY?JJJ??????Y555GGBGYYJJYYY#@@@B^^^^^^^^^^^^^[email protected]@@@57?JJJ???????77?7777????????7?7?JJJYJJ77?JJJYYYYYY    //
//    JJ?JJJ??????JY55PGBGYYJYYYY#@@@B^^^^^^^^^^^^^[email protected]@@@57?JJ???7????777777?77777777???JJJJJJJ77?JJJYYYYYY    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WHOOV is ERC1155Creator {
    constructor() ERC1155Creator("TheWhoove", "WHOOV") {}
}