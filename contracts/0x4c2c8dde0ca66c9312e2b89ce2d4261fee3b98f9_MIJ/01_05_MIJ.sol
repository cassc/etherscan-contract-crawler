// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: UnknownGallery
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    &&&BGGGGP!JJPP~J!JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJY!!!7??JPB5PGPPPPP555PP    //
//    &@&&5YY5J~?JY5~7!7JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ7~~!777J5PJJYJJJYJJJJYY    //
//    &&&&G????~?YYYJ!?!JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJY5P57YPPP5555PPGGGGBBB#    //
//    &&&&#J777^!JJJJ~?~JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJY?5Y!Y55YGBBBBBBBBBBBB#    //
//    &&&&&G!!7~~???J~7!?JJJJJJJJJJJJJJJJJJJJJJJJJJJYJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ?7J7JYYYYPPPPPPGGGPGGGB    //
//    &&&&&&J~757!7?7~!!?JJJJJJJJJJJJJJJJJJJJJJJYJJJYJJJYJJJYYJJJJJJJJJJJJJJJJJJJJJ!7!!JJYJY5PPPGPGPPGPGGB    //
//    &&&&&&B!!5?!!77~~77JJJJJJJJJJJJJJJJJJJJJJJYJJJ5YJYPJYYP5YYYYJJYJJJJJJJJJJJJJJ7!?JJJJ?Y5GGGPGGGGGGGGB    //
//    &&&&&&&5~J7~!777^?7JJJJJJJJJYJJJJYJ5PJJJJY5JJJ5YY5GYPPGPPP5YJYYJYJJYJJJJJJJJJ?!??????J5PPPGGGGPGGPGG    //
//    &&&###&#77!~!7!7^7!JJJJJJJJJYYJJJ55PGYJ5GPP5YPGGPGBGGGGGGGPPP55YYJJ5JJJJJJJJJJ!~!!7?YY5GGGGGGGBGGGGB    //
//    &&####&&P~!~!7!7^!!?JJJJJJJJJYYYJ5GGBGPGBBBBGBGBGGGBBGPGGGPPGPP5YJY5JJJJJJJJJJJ!??JYYJ5GGPGBPPGGGBGG    //
//    &&&&&&&&&J~~!!!7^!!?JJYPYJYYYPPG5PBBBBBBGBGBBGGGGGGGGGPPPPPPPPPP5PP5YJJJJJJJJJJ?!7JYJJ5BBBBBGGBBBBBB    //
//    &&&&&&&&&B!~~!!!~!7?JJ5P5Y5PPGBBBGBGGBBGGBGGBGGGGGGGGPPPPPPPPP5PPPPP5JJYJJJJJJ?J77!7?JPBGGGPGGGPGGGG    //
//    &&&&&&&&&@5~~!!!^~7?JJ5GGPGBGPGBBGBGGGBGGGPGGGPPGGGGGPPPPPP5PP555PP55JJYJYYJJ?????7???PGGPPPPGPGGGGG    //
//    #&&&&&&&&&#!~!!~~~~7JJ5PGBGGP5PGGGGPGGGGPGPGGGPPGPGGGPPPPP5555555PP555555Y5YJ?J???????5GGP55PPPGPPGG    //
//    B#&&&&&&&&&5~!!!!~~7Y555PPG5YJYPGGG5PGGPPGPGGGPPPPGGPP5PPP555555555555555555JJJ??????J5GBBBGGG5PGBBG    //
//    GB#&&&&&&&&#7~~!!~~?GGYY555YJJJ5PPG5PGGP5G5PGPPPPPPGP55555555YY5Y55Y55555Y5YJJJ???????5PPPGGBBPGB##B    //
//    GGB#&&&&&&&&P~~!!~~!PPYJ5YYJJJJY5PG5PGG5YG5PGPPPPPPGP5Y555YYYYYYY55YY55YYYYJ?JJ??????JGGPPPGGG5PGGGB    //
//    GPGB&&&&&&&&&?~77~~!55JJYJYJYPP5Y5G5GGP5YP5PGP5PPPPP5YJYYYJYYJJYYYYYY55YYYYJ??JJJJ???JGGBBB#G5Y5GBBB    //
//    PPPGB&&&&&&&@G~!7~~~YYJJY5YBBBBGGGGGGP55JPPPPP5PPP55YJJJJJJJJJJYJJYJY5YYYYYJ??JYY5YJ??PBGBBB#GBBB###    //
//    PPPGGB&&&&&&&&?~?!~^JYJYPP5BBBBBBGGBG55G5PPPP5Y5P5Y5JJJJJJJJJJJJJJJJJYYJYJJGBG5YJY55YJPGGGBBBGPPG&&&    //
//    PPPGGG#&@@&&&&G~77~^7PGBGBBBBBGGGGPGG5PGBG55P5Y555YYJJ?77!!!7??JJJJJJYYJJJJPGB#&#BGGGPGBB###PPGG####    //
//    PPPGPPB#&&&&&&&?!7~^7BBBGBBBBGGGGGPGG5PGBG5Y5YYY5YYJ7^:::::::::~?JJJJJJJJJJ55PGG##&##BGGBB#########&    //
//    PPPP55GP#&&&&&&P~?!~~GBGGGBBGGPGGP5GGPGPBPG55JJYYJY!:::::::::::..~?J?!!!?J?5GPPPPGB#&BBG########&&##    //
//    P55PYJPYG&&&&&&&?7?!^GBBPGGGGGBGGP5GPGGGBPGG5YJJJJJ:.::~!^~^~^^:..:7PJ!^^7?PPPGPPPGG#BBB########&&&&    //
//    555PYJPYYB&&@&&&G!J!^PGGPGGGPGBPGP5GPGGGGPPG5GBYJP5::^7JY~!!~~~^::..YBBPYJJ555PPPGBBB#BBB##BB###&&#&    //
//    5555YJ5JJ5B&@&&&&J!?^5GGPGGGPPGPPPYP5PPGG5PG5G#BPBG~:~7?J!~J!~!!^^:.7PPGBBGP5Y5PBBBBB##########&#&##    //
//    5555YJ5JJYGB&&&&&B!?~JGGPPGPPPPPPPPP5GPPG5PG5GB####7:~!7?!^??~~~^^:.JPPPPGBBGBGGGBG#B##B##&&&&&####&    //
//    Y5Y5J?5??YPGB&@&&&5!~7GGGGPPPGPPP5PP5GPPG5GGGBB###G^:~~7?7~7?~~~^~^:?55555GGGBB##BPBB##B##&#&&&&&&&#    //
//    Y5YYJ?Y??J5PPB&@&&#7J~PPPPP5PP555555YP5PP5GGGG###B!::^~7?Y?7J?!777!^^?Y55PGGGBBBB#B###B###&&##&&&&&&    //
//    YYYYJ?Y77J5555B&@&&PJ~5P55P5555Y5Y55Y555555555P#B!:::^^!7J?!7!!!7!~^^^7PGBBBGBBBGBG&&&####&&&&&&&&&&    //
//    YYYYJ?J!7JYYYYP#@@&#Y!JPY55555Y??!!!!?JYYYYYYY5G~:^:^^:^~?7^^^^!!~^::::7GGBBG###BBB&&&&&&&&&&&&&&&&&    //
//    [email protected]&&P?Y5YYYYYY5?!~!J!^~?JJJYJJY~::^^^^::^!?^:^^~::.::.::!JPB#####B#&#&&&&&&&&&&&&&&&    //
//    JJJJ??JJ!?YJJYYY5#@@&5J5YJJJYJPY??YJ?J??JJJJJJ^::::.:::::7PPJJ~~~::!7....!Y?J5G#&##&&&&&&&&&&&&&&&&&    //
//    JJJJ??JBY?JJ?JYYYP&@@#5YJJJJJP55G#B?Y#BY?JJJ?^::::..::::?P5PJYJ7JYYYY!:...5#G5J?YG#&&&#&#&@&&&&&&&&&    //
//    JJJJ??JP??JJ?7JJYP&@@@GJ!!!!!Y5J5G5BPG5????7:::::::::::~Y55PJJY7J55YJJJ~..^G###GPYY5GB####&&&&&&&&&&    //
//    JJJJ?7JP7?JJY7?JJ5&@@@BY~^^^^~5#G5J5Y5!^^^~::^^:^:.:^::^J55P?JY7?55YJJYY!..?####&@&#######&&&&&@@@@@    //
//    JJJJ77?5!7??J77?JY#@&@#57^^^!!!YYY?YYPP5?^:::^^::^:^^^:^J55P7?Y!?Y5YJJJYY7^^G&##&&&&&&&&&&&&&&&&&&&&    //
//    J????Y?5~7??777??J#@@@&5?!J5G?.~JY5J7Y5J!^^^:::^:^^^^^:^?Y55?7J!?YYYJJJYJJ7:?&##&&&&&&&&&&&&&&&&&&&&    //
//    [email protected]@@@P?::^~^:???5J7~~~~^^::::^^^~~~^^^7YY5?!7~7YYJ??JJJJJ~:G&#&&&&&&&&&&&&&&@&&&&&    //
//    ????5BJP#[email protected]@@&&G!.......:::::^^^::::::^^~~!~^^^~JY57!!~7YYJ??JJ??J7:7##&&&&&&&&&&&&&&&&&&&&    //
//    ????YGJ5BGYY55YY5P&@@@#&@Y:.:~77^::^^:^::::^::?7~~!~~~^^~7Y57!~~7YY?77?J???7:^P&&&&&&&&#5B#&&&&&&&&&    //
//    ???7YG?5BB5&@@@@@@@@&#P#@Y::::?PPY!^~^~~^^^:~JBP?7~~~~^:^~J57!~~!JY?77?J?77!::!#&&&&&&@&5G#GJB&#&&&&    //
//    ??77YP?5GB5#&&&&###BBGG&@?::..:7Y5G5?!~~!!~JGGGGGJ^~~~~^^~?Y7!~~!JJ?777?77!!^:^Y&&&&&&&&&&&G7G#B#&&&    //
//    ??77YP7YGBGBBGGGGPPGG#&BY~^::::^~!5PGG55J.~GGGGGY^^^^^^^:^7Y!!~~!??777!?77!~^:^!#@&#BB#&#&&P?5B###&&    //
//    ??77YPYYGBB#GGGPPPPGGBG?~~~^::::^~75PGGG7.JGGGGG7^~^~^^^::~J!~~^~7?777!77!~~~:^^P&##J7G&&&&G?JB###&&    //
//    7777JGGYPGBBGPPP55PPGG57??7~^:::^~~7YPPP~!GGGGG5!~~~~^^^^:^?!~~^~777!7!!!~^^~^:^7&##P5BBPPGP55B#BB#&    //
//    7777JPPYPPGBGPPP55PPPPGG5PP5!~^^:^~~~?5?.!PPGPJ!~!~~^^^^^:^7!~~^~!!!!!~~~^^^^^:^~PG###BPBGPGG##BBBB#    //
//    [email protected]&55J!!~~~^^~^^!~.:7J?7~~~~~~^^^^^^:!~~~^^!~^~~^^^:^^^^:^~?5PGBBY55PBBBBBBB#&    //
//    7777?5YJ555PPP5555PPPPP&&P5?~~~^^^^^^^!~~~~!^:~!~~~~^^^::::^~~^^^~~^^^::^:^^^^:^^!J5P5YJ5#&&&&&&&@@@    //
//    77!!?YYJYYY5PP55555PPGB#&GJ7~^^^^^^:^^!~^^~!^^7!~~~~~~^:::::~^^^:~~^^^:::^^^^^:^^~!5P5YJ5GGGGBBB####    //
//    !!!!JPY?YJY55555YY5PPPBB&B?J!^^^^^~^^^~::::^^~7!~^~~~~~^::::^^^^:^~^^^:::^^^^^:^~^~J5Y??PBBBGGGGBBBB    //
//    !~~7B#57JJGP5P5YYY5PPPGB#B??!~^^^^^^^^^^:...^77!~^~^^^~~^:::^^^^:^~~^^^:::^^^^^^!^~?GGPP#GGGGGGGGBBG    //
//    ?!JG###J?P##GGPYYY555PGB##?7~~^^^^^^^^^^:...:7!!~^^^^^^~^^::^^^^^^^!^^^^::^^^^^^!~^!GBBBBBBBBBBBGBBB    //
//    #BB##&&#5##BBBPYYYY555GB#&Y7!!~^^^^:^!^^^^::~7!~~~~^^^^~^^^:^~^^^^^~~^^^^:^^^^^^!!^~JPPGGGGPPGGGBB##    //
//    ##BB#&&&####B#GYYYY555GBB&P7777^^^^^^!7!~~^^7!!~~~~^^^^~~^^::^^^^^^~~^^^^^^^^^^^~7~~?55PPPPPPPGB####    //
//    ##B###&&&###B#BYJYY55YGB#&P!!!!~^^^:~!!!~^^~!!~~~!~~^^^~~^:::^^^^^^~~^^^^^^^^^^^~!!^!Y5555GBB#####&&    //
//    ####B#&&&######5JJJYGBGBB&G~~~~~^^^!!~~~~^^~~!~~!~~~~~^~~^:^:^~^^^^~~^^^^^^^^^^^~!!^~?Y55GB#########    //
//    ######&&&&&&###BYJ?YB####&B~~~~~^^!!~~~~~^^~~~~~~~~~~~~~~~^^:^~^^^^~~~^^^^^^^~^^~~~~^?##BBBB#BGPPGBB    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MIJ is ERC721Creator {
    constructor() ERC721Creator("UnknownGallery", "MIJ") {}
}