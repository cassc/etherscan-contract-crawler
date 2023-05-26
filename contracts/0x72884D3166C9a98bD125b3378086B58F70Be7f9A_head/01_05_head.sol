// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: unBlock Heads
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    ........................................................................................................................    //
//    ..................................................................................:^^^..................................    //
//    ....................................................:^^::.......:....::::::.:::^^^^^^:..................................    //
//    ..............................................::::::^^^^^^:::^^^^^^^^^^^^^^^^^^^^^^^::..................................    //
//    ............................................:^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^::.............................    //
//    ...........................................^^^^^^^^^^^^^^^^^^^^^^^^~~^^^^^^^^^^^^^^^^^^^^^^^^^::........................    //
//    ....................................:::^:^^^^^^^^^^^^^^^^^^^^~~!!!~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^:......................    //
//    ..........................::....::^^^^^^^:^^^^^^^^^^::^^^~!777!~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^:.....................    //
//    .......................::^^..::^^^^^^^^^^^^:::^^^^^~!!7?77!~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~!!~^:::................    //
//    .....................:^^^^^:^^^^^^^^^^^^^^^^^^~!7???7!~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~!7?J?JJYJJJJ?7^.............    //
//    ...............:::^:^^^^^^^^^^^^^^^^^:^^^~!7?JJJ?7~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~!77?J?JJJJJJJJYYYYY?^...........    //
//    .............:^^^^^^^^^^^^^^^^^^^^^^~!??JJJJ?7!~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~!7?JJJJJJJJJJJJJJJYYYYJYJ~..........    //
//    ............:^^^^^^^^^::::^~^:^^~!7JJYYJ?7~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~!7??JJJJJJJJJJJJJJJJJJJJYJJJJ7..........    //
//    ...........:^^^^^^^^^:~JYG##GPG5YYYYJ?!^^::^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~!?JJJJJJJJJJJJJJJJJJJJJYJJJJJJJJ?^.........    //
//    ..........:^^:::::^^~J&&&&##&&&&BJJ?!^^^^^^:::^^^^^^^^^^^^^^^^^^^^^^^^^~~!7??JJJJJJJJJYJJJJJJJJJJYYYYYYYJJJJJJJ?~:......    //
//    ..........^^^~!7JYPGB&@&@&&&@&@@&BGP5YYJ??777!~~^^^^^^^^^^^^^^^^^~~~!7??JJJJJJJJJJJJJYJJYYJJJJYYYYYYJYYYYJJJJJJYYJ~.....    //
//    .......:7?5PGB#&&&&&&@@@@@@@@&&@@@@@@&&&&##PJYJJJ?!~^^^^^^^^^^^~7??JJJJJJJJJJJJJJJJJYJYYYYYJJJJJJJJJJJYYYJJJJJJ^::......    //
//    .......7&&&&&&&&&&&&###&B#&##&@@@@@@@@@B&#@#JYJJJJYJ?!^^^^^^^~7JJJJJJJJJJJJJJJJJJJYYYYJJJJJJJJJJJJJJJJJJJJJYYJJ.........    //
//    .......Y#&&&&&&&&#5^^^^~^~!7JP#@@@@@@#GJP&@#JJJJJJJJYYJ7~^~!?JJJJJJJJJJJJJJJYYYYYYYYYYJJJYJJJJJJJJJJJJJJJJJJJJ?.........    //
//    ......JPP#&&&&&&B~.~^^^^^^^:..:[email protected]@@@&J?Y#@@#JJ??JJJJJJJJJYJJ??JJJJJJJJJYYYYYYYYYYYYYYYJJJJJJJJJJJJJJJJJJJJJJJY~.........    //
//    ......^GGP55PPGPPP##~^^^^^:.75~?#@@&YJ#&@@@#J??JJJJJJJJJJYPPYJ???JJJJJJYYYYYYYYYYYYYYJJJJJJJJJJJJJJJJJJJJJJJY7..........    //
//    .......G&&&&#BG#&&@#^^^^^^^?#@&5JBG7Y&&&&&&BJ?JJJJJJJJJJJJPPPP5J?JJJ?JJJYYYYYYYYYYYJJJJJJJJJJJ???JJJJJJJJJJY7...........    //
//    .......P&&&&&&&&&&&GYJJ??J#@@@@&5J?JGG5YYYGG???JJJJJJJJ??J5PPPPP?JJJJJJJJJYYYYYYYJJJJJJJJJ?????????JJJJJ?JJ!............    //
//    .......P#&&&&&&&&&&######&&&&&&#PY555YYJJYGP???JJ???????JJPPPPPPY??JJJJJJJYYYYYYYJJJJJJJJ???????????JJJJJ7:.............    //
//    .......5#&&&&&&&&&&&&&&#&&&&###&BPYYYYYJJYBP???????JJJJJJJPPPPPPP5YJJJJJJJJYYYYJJJJJJJJJJ?????????????J?~...............    //
//    .......5#&&&&&&&&&&&#&&&#BGG&&&GYYYYYYYYY5BP??????JJJ?JJJJPPPPPPPPPJJJJJJJYYYYJJJJJJJJJJ??????????????J?................    //
//    .......5#&&&&&&&&&&###&&57?B&#PYYYYYYYY5Y5G5??J????JJJJJJJPPPPPPPPP5JJJJJJJJJJJJJJJJJJ?????????7??????JJ~...............    //
//    .......5#&&&&&&&@@@&##&&5JB&##BP5YYYJY5YJ5G5JJ????JJJJJJJJPPPPPPPPP5JJJJJJJJJJJJJJJJJ???77??7????????JJJJ...............    //
//    .......P&@@@@@&&BG###&&GY5GGB&&#PPPPPPP5PGBYJJJJJJJJJJJJJYPPPPPPP5J?JJJJJJJJJJJJ?JJ????7777???????77?JJJ7...............    //
//    .......JGGPY7~:...B&#&&BJYBBBBPYYYY5555PPP5JJJJ?????JJJJJYPPPPPP5J??JJJJJJJJJJJJJJ????7777??7??7777????!................    //
//    .................!&&&&&&&GYY5YJJJJJJJJJJJJ??JJJYY5555YJJJJ5PPPPP5??JJJJJJJJJJJJJJ???????????7?777?JJJJ~.................    //
//    .................~BB#&&&@@&BYJJJJJJJJJJJJY5G#&&&@&&&&&&&BGP555PPPYJ?????JJJJJJJJJ????JJJJJ????????JJJJ!.................    //
//    ..................YB####&#&@#JJJJJJJJJYPB#&@@&&#BGP5PPGGB###BG55PPPYJ??????JJJJJ???JJJJJYYYYJJ?JJ??JJ?J:................    //
//    .................:YPGYJB#YP##5JJJJJJJJYPB###GP555YYYYYY5555PPP55YYY55J????????JJJJJJJJJJYJYYYYJ????JJJJ^................    //
//    .................^55GGBGYYYY5YJJJJJJJYY5PP55YJJJJ????JJJJJJYYYYYYYJJYJ??????????JYYYJJY5PP5YYYYYJ???JJ7.................    //
//    .................~5~P####BPYYJJJJJJJJJJJ5Y5PPPPGGGGGGGGGPPPP55YYYJJJYYJ???????JJJYYJYB##BBBBPYYYY???7^..................    //
//    .................7Y:JGGGB#PYYJJJJJJYJJ?J5B&@&&&&&&######BG55YYJJJJJYYYJ?7777?JJJJJJYB#BBGGPG#5YYYJJJ?^..................    //
//    .................J5Y5PPGGG5YYJJJJJYYJJ?JB&#G55YYJJJJJYYYYYJJJJ?JJJJYYJ777?Y5J??JJJP#&#&#BGPG#5YYYJJYJ^..................    //
//    .................Y7^JJY55P5YJJJJJJJJJJ???JJYYYYYYYYJJJJJJJJJ????JYYYYJYY5PPPP5YY5PGP55#&GPPB#5YYYJ?~....................    //
//    ................:5~:???YP5YYJJJJJJJJJ?J????JJ???J??????JJJJJJJJJYYYYYJ5PPPPPPPPPP5YYJ5#BPPGBPYY!^:......................    //
//    ................~5^^YJJPGYYYJJJJJJJJJJ?JJJJJ????JJJJJJJJJJJJJJYYYYYYYYPPPPPPPPPPP555GG555GG5Y?:.........................    //
//    ................75?JPPPGGYYJJJJJJJJJYJJJJJJ?????JJ??JJJJJJJJJYYYYYYYY5PPPPPPPPPPPPY55YYY55JJ!^..........................    //
//    ................?J:^7JY55YYJJJYYYYYJJYYJ???????JJJ??JJJJJJJJJYYYYYYYYPPPPPPPPPPPPPY?77YYYY?~^!..........................    //
//    ................J! .^JJYYY5YYY555YYYY55Y???????JJJ??JJJJJJJJYYYYYYYY5P5PPPPPPPPPPY~!!7YJ?7~^:...........................    //
//    ...............:Y^...~GG5Y5P5YYYY5555YPPJJ????????????JJJJYYYYYYYYY5555PPPPPPPP5!..~DMT:................................    //
//    ...............^J.....~YYYJ5BBGGGB#BBBGY?JJJJ???JJJ???JJJJYYYYYYYY5555555PPPPY~.........................................    //
//    ...............!J~^....!YYJYYGBB###BGY???????JJJJYJJJJJJJYYYYYYYY5555555PP5?^...........................................    //
//    ...............77:~!!^.7J5P555555PP5JJ???J????JJJJJ??JJJJJJJJJY5PP555PPPY!..............................................    //
//    ...............?~...^!7J7PBGBBGGGPPP555YJ?????JJJJJJJJJJJJJJY5PPPPPPP57^................................................    //
//    ...............?^.....^J::!PG55PPPGGGGBGPYJY5YJJJJJJJJJJJJJYPPPPPP5?^...................................................    //
//    ..............:J!!^:..~?.. :J5YYYYYY5PGBGGP55YJJJJJJJJJJJY5PPPP5?~......................................................    //
//    ...............:.:^!~^7!.....^YPPPP5555YJJJJJJJYYJYYYYY5PPPP5?~.........................................................    //
//    ....................:^?^..... ^GBBBBBB5JJJJJJYYYYYYYY5PGP5?^............................................................    //
//    ......................~........^Y555P5YYYJJJJYYYJJY5P5J!:...............................................................    //
//    .................................^!?JY55555YYYYYJ?7^:...................................................................    //
//    .....................................:::^^^^:::..................................................................unblock    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract head is ERC1155Creator {
    constructor() ERC1155Creator() {}
}