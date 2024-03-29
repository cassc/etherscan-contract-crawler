// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DESPAIR
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                    //
//                                                                                                                                                    //
//    ............................................................................................................................................    //
//    ............................................................................................................................................    //
//    ............................................................................................................................................    //
//    ...............................................................:::::::::::::::::::::::::::..................................................    //
//    ......................................................::::::::::::::::::::::::::::::::::::::::::............................................    //
//    ................................................:.::::::::::::::::::::::::::::::::::::::::::::::::::........................................    //
//    ..............................................:::::::::::::::::::^::^^:^::^^^^^:^:::::^::::::::::::::::.....................................    //
//    ..........................................:::::::::::::::::^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^:::::::::::::..................................    //
//    .......................................:::::::::::::^^^^^^^^^^^^^^^^~^^^^^~^~~^^~^^~^^^^^^^^^^^^^^^:::::::::................................    //
//    ....................................:::::::::::^^^^^^^^^^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^::::::::..............................    //
//    ...................................::::::::^^^^^^^^^~~~~~~~~~~~~~!!!!!!!!!!~!!~!!!!!~!!~!!~!~~~~~~~^^^^^^:::::::............................    //
//    .................................::::::::^^^^^^^^~~~~~~~~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~~~~~^^^^^:::::::..........................    //
//    ................................:::::::^^^^^^~~~~~~~~~!!!!!!!!!!77?YYYY?777777777777777777!7!!!!!!!!!~~~~^^^^^::::::........................    //
//    ...............................:::::::^^^^^~~~~~~!!!!!!!!!777?Y5GB#&&@@#BPYJ???????77?77777777777!!!!!!!~~~^^^^::::::.......................    //
//    ...............................::::::^^^^~~~~~!!!!!!!!!77!77J5PPPPB#BBB#@@@&BBBGP5Y??77????77?777777!!!!!!~~~^^^^:::::......................    //
//    ..............................::::::^^^^~~~~~!!!!!!!!~~~~~!7?J?JPG#BGG5?YB&@@@@B5YYYYJ???????????777777!!!~~~~^^^:::::......................    //
//    .............................::::::^^^^^~~~!!!7!!!~^:::::^!7?7?PP5G#@@@P~^!JPBBPYGGGG5JJ?????J??????7777!!!!~~^^^^:::::.....................    //
//    .............................:::::^^^^^~~~~!!7!~^:....:::^~!!!YP?7YP#@&BJ~^::::^^~!?G&#GYJJ??J??????7777!!!!!~~^^^^::::.....................    //
//    ............................::::::^^^~~~~!!!!~^:......:::^~!!7Y?^^!?5#BPY7!^::::.:^~75&@&GY?JJJJ????7?7777!!~~~~^^^::::.....................    //
//    ............................:::::^^^^~~~~~!!~:........:::^^~~!5BY??J5YJ??77!~^:.^!~::[email protected]??????7??777!!~~~~^^^::::.....................    //
//    ............................:::::^^^^~~~!!!~:...........::^^^!YPYJ??7777?7?JJ!:.^7~:^[email protected]@@&B5J???????777!!!~~^^^^:::::....................    //
//    .............................::::^^^^~~~~!~:.............::::^^::::^^^~!!!7YPJ~~!7JPG&@@@@@@@@@BYJJJJ??777!!!~~^^^^::::.....................    //
//    .............................:::::^^^~~~!!^:.........................:^^^~?5PYP#&&@@@@@@@@@@@@@@PJJJJJ??777!!~~~^^^::::.....................    //
//    ............................::::::^^^^~~!~^.........................::^:::75PB&@&#GP55PPPPPB#@@@GYJJJJ??777!!~~~^^^::::.....................    //
//    ............................::::::^^^~~~~~^......................::::^^^::!75BGY7~~!J5PGGGGBGP&@BYJJJ???777!!~~~^^:::::.....................    //
//    ............................:::::^^^~~~!!!^:....................:::^^^~^::^?GJ~^::::^[email protected]#YJJJ???77!!!~~~^^^::::.....................    //
//    ...........................:::::^^^^^~~!!!~:.....................:::^^^^::~P5^...............:7##5JJ????777!!~~~^^^::::.....................    //
//    ...........................::::^^^~~~!!!77!^:......................::::^::?G7:................!GGYJJJ???777!!~~~^^^::::.....................    //
//    ..........................:::::^^^~~!!777??7~:.....................::::^::?G7:...............^5&PYJJ????77!!!~~~^^^::::.....................    //
//    .........................::::^^^^~~~!777?J?J?!:......................::^^:7BJ:...............~B#5YJJ???777!!!~~^^^:::::.....................    //
//    ........................:::::^^^^~~~!!77?JJYYJ7^:....................:::^:~B#7^::............~P#PJJJJ?J?77!!!~~~^^^::::.....................    //
//    .........................:::::^^^^^~~!!!77?JJYY?!^:...................::::^[email protected]?!!!!!^:....~PB5YJ?J??777!!!~~^^^::::.....................    //
//    ............................:::::::^^^^^^~~!!7JJJ?!^:..................::::7&@#PPPGPGPPPYJ7~^[email protected]??77!!!~~^^^::::.....................    //
//    ................................:::::::::::^^^~~!7??7~^:................:::!G#PY5P#&@@@@@@&##&@@@BPP5YYJJ?77!!~~^^^::::.....................    //
//    .................................:::::::::::::::^^^~!!!~^::..............::~YGJ!!7YPGB#&&@@@@@@@&BGPPP5YYJ?7!!~~^^^::::.....................    //
//    ................................:::::::::::::::::::::^^^^^^::..............:7GBPJJ5#&&&@@@@@@@@@@@@B555YYJ?7!!~~^^^::::.....................    //
//    ..................................:::::::::::::::::::::::::::::.............:7P#&#GB&@@@@@@@@@@@@@@#Y5YJJ?77!!~~^^^:::......................    //
//    .................................:::::::::::::::::::::::::::::::..............:~77?7??YPPBBBBBGGB#&G5YJ??77!!~~~^^:::.......................    //
//    ....................................:::::::::::::::::::::::::::.......................:::^^~~~!!7J5JJJ???77!~~^^::::........................    //
//    ........................................::::::::::::::::::::::::...........................:^~~~~~~~~!!!~~~~^^:::::.........................    //
//    .....................................::::::^^^^^^^^^^^^^^^^^^^^:...........:.....::::..:::^~~~~~~~~^^^^^^^::::::::..........................    //
//    ...................................::::::::^^^^^^~^^^~~^~~~~^::...........:::.:~7!^:..:^^^^^^^^^^^^^^^^^^^::::::::..........................    //
//    ....................................::::::::::^^^^~~~~^^^^^::...........:::::::7J7^:..:^^^^^^^~^^^^^^^^^::::::::............................    //
//    ...................................::::::::::::^^^^^:::................::::::.:~!!~:.::::::::^^^^^^:::::::::::..............................    //
//    ................................::::::::::::::::::......................:^^^:.:^~!!^:::::::::^^^:::::^::::::................................    //
//    ...................................:::::::::::::........................:^^^::.:^!!^:::::::::::::::::::::...................................    //
//    ....................................:::::::::::........................::^^^^:.:~!~:::::::....::............................................    //
//    ........................................:::.........................::::::^^^:::^~^::^::::..................................................    //
//    ..................................................................::::::::::^:::^^::::::::::................................................    //
//    ...................................................................:::::....::::::::..:::...................................................    //
//    .....................................................................:::....................................................................    //
//    .....................................................................:::::..................................................................    //
//    ............................................................................................................................................    //
//    ............................................................................................................................................    //
//    ............................................................................................................................................    //
//    ............................................................................................................................................    //
//    ............................................................................................................................................    //
//    ............................................................................................................................................    //
//    ............................................................................................................................................    //
//    ............................................................................................................................................    //
//    ............................................................................................................................................    //
//    ............................................................................................................................................    //
//    ............................................................................................................................................    //
//    ............................................................................................................................................    //
//    ............................................................................................................................................    //
//    ............................................................................................................................................    //
//                                                                                                                                                    //
//                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ALLEGORY is ERC721Creator {
    constructor() ERC721Creator("DESPAIR", "ALLEGORY") {}
}