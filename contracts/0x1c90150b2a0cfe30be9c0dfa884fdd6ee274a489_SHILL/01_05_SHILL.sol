// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SHILLSPEARE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                     //
//                                                                                                                                     //
//    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPPPPPPPPPPPPPPPPPPPPPP5J??JJYY55Y?7!!~~~~^^^^^^:::::::::::::::..:::::    //
//    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5J?77777?JJ?!!~~~~~^^^^^^^::::::::::::::::::::::    //
//    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5J?777!!!77!!!~~~~~^^^^^^^::::::::::::::::::::::    //
//    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP55555YJ??7777!!!!!~~~~^^^^^^^^^^::::::::::::::::^^^^    //
//    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPPPPPPPPPPPPPPPPPPPPGGGGGGBBBBBB##B####BBGGP55JJ??777!!!!~~~~^^^^^^^^^^^::::::::::::::^^^^^^    //
//    PPPPPPGPGGGGGGGGGGGGGGGGPPPPPPPPPPPPPPPPPPPPPPPPPGBBBB#BBB##BB#B##&&&&&&&&&&&##BP5J?77!!!!~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGBGGPPPPPPPP5555PGGGGGB##&&&&&&&@@&&#PY7!!!~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^~~~~~    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGBBPYJ?777777!7!!777???YPGGB##&&&&&&&@@@@&BY!!~~~~^^^^^^^^^^^^^^^^^^^^~~~~~~~~~~~    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGG5?!^^::::::::::::^^^^~!7J5GB###&&&&&&@@@@@&GJ!~~~~^^^^^^^^^^^^^^^^~~~~~~~~~~~~~!    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGGJ!^:..............::::^^^~!?YPBB##&&&@&&@@@@@@&P7~~~^^^^^^^^^^^^^^^~~~~~~~~~~!!!!!    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPG5!:.....         ....::::^^!!!7YPBB##&&@@@@@&@@@@&G?~~~~^^^^^^^^^~~~~~~~~~~!!!!!!!!!    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP?:....             ....:::^^!777?YPBB#&&&@@@@@@@@@@&BJ~~~~~~~^^~~~~~~~~~~!!!!!!!!!!!!    //
//    555555555PPPPPPPPPPPPPPPPP55555555555PP7:...               ...:::^^~7JJ77?YPBB#&&&&@&&&@&@@@&G?~~~~~~~~~~~~~~~!!!!!!!!!!!!777    //
//    5555555555555555555555555555555555555P7:....              ...:::^^^!?JJ???YPGB#&&&&@@@@@@@@@@#P7~~~~~~~~~~~!!!!!!!!!!77777777    //
//    555555555555555555555555555555555555P?^:.....            ...::^^^^~7JYYJ?JYGB##&&&&&&&@@@@@@@&#57~~~~~~~~!!!!!!!!!77777777777    //
//    5555555555555555555555555555555555555~^::.....       .....::::^^^^!?YY5YYY5GB##&&&&&&&&@@@@@@&&#57~~~~!!!!!!!!!7777777777777?    //
//    55555555555555555555555555555555555PJ^^::::.............::::::^^^~7JYY5555PGGB###&&&&@@@@@@@@@@@&GY7!!!!!!!!!7777777777??????    //
//    5555555555555555YYYYY5555555555555557^^::::...........::::::::^^~!?JYYYYY55PPGB#&&&&&@@@&&&&@@@@@@&BY7!!!!!77777777??????????    //
//    555555555555555YJJJJJYYY555555555555!^^:::::..............::::^^~!7?JJJJJY55PGBB#&&&&&#B##&&&&&&@@@@&G?777777777?????????????    //
//    55555555555555YJ?JJJJJYY55555555555Y~^^::::........      ..::^^^~!77???7?JY5PGB##&&&#########&&&&@@@@&GJ7777?????????????JJJJ    //
//    555555555555YJJJJJJJJYYY55555YYYYYYY~^::::.........:~7?Y5PGBB#####&&&##GPB##&&@@@@@&@&#########&&&@@@@#PJ????????????JJJJJJJJ    //
//    55555555555YYJJJJJJYYY55555Y5PPGGBB#BBBGGGGPY7:::!G&&#BBGGGGBB##&&&&&&&@@@@BB&@@&&&&&&&&@&&&&&&&&&&@@@#BGYJY55J???JJJJJJJJJJJ    //
//    5555555YYYYJJJJJJYYY55555Y5#&@@&&&&&#BGGGGGB#&G?Y&@#GPPPGGB##&&&&&&&&BB&&BB##&@@@@@@@@@@@@@@@@@@&&@@@@&&#BGG##5JJJJJJJJJJJJJJ    //
//    [email protected]#GG#&####BBGGGGGPG&@@@&B#BBB####&&&&&&@@@@@@@&&&&&&###B#B###&@&&&@@@&&&@&@@@&&&&&BGPYJJJJJJJJJJJJ    //
//    5555555555555YYY555555YYYJY&&GB#&&&#######BBBB&@@@&#######&&&&&&@@@@@@@@#GGGGGGGGGGGGGGGGB&#B#@@&&&&@@@@@@@&&###PYJJJJJJJJJJJ    //
//    [email protected]@&&&&##&&&&&###&&[email protected]&&&&&&&&&&&@@@@@@@@@@GPPPPPGPGGBGPPPGGG&&[email protected]@&&&&&@@@@@@&&@&#G5YYYYYYYYYYY    //
//    55555YYYYY5555PPPPP5YYJJJ??77#@&&&&##&&&&&&&&@5.^[email protected]@&&&&&&&@@@@@@&&&&@BPPPPGGPPGBBPPP5B##BGG#@@@@&&&&&&&&@@&&#BB5YYYYYYYYYYY    //
//    [email protected]@&&###&&&&&&@#~:755G&@@&&&&&&&&&&&&&&&#GGGGGGPPPGBBPP5B&[email protected]@@@@@@@@@@@@@&&&&#P5YYYYYYYYYYY    //
//    555YJJJJJJJYY55555PPP55YJ?777!75#&@&&&&&@@@@@Y^^?PGP5PB&&@@@@@@@@@@&&#[email protected]@@@@@@@@@@@@@@&&&BP5YYYYYYYYYYYY    //
//    YYJJJJJJJJJYYYY555PPP5YJ???7777!7?Y55PGGGGP5J!^!JPGGP5YJ77?JYYYYYYJJJJJY5PPPP5PGB##GPP555P#@@@@@@@@@@@@@@@@&#G55555YYYYYYYYYY    //
//    JJJJJJJJJYYYYY555PPPP55YJ???77777777777?!~^^~~^!YPGGPPPP?^::::::^^^~!!7?Y5PP55PGB##GP#BB#&@@@&&@@&&&&&##BGPY55555555555Y5YYYY    //
//    JJJJJJYYYYYY555PPPPPPPP55YJJ?????????????!~~!7?YGB#&&#GGG~^^^^~~~~!!77?Y5PP55PGB###GP&@@@@@@@&@@@@&&#G5YJ???J5555555555555555    //
//    JYYYYYYYYYY555PPPPPPPP55YYJ?????????????J?7!~!?YGB#&&##G?:::^^^~~!!7??J555555GB####GP#@@@@@@@&&@@@&@&&#PYJ?77Y555555555555555    //
//    YYYYYYYY5555PPPPPPP55YJ?????????????JJJJJJ?7!!7YBBB#&&&GY?7!~^^~~!!7?JY55YY5PB#####BP#&@@@@@@@&@@@@@@&#GP5YJ?JP55555555555555    //
//    5555555555PPPPPPPPP5YJJ????????JJJJJJJJJJY5Y5G#&&##&#&&&&&#BG5J?777?JYYYYY5PGB#####GP##&@@@@@@@@@@@@@&#GP5YJJ75P5555555555555    //
//    55555PPPPPPPPPGPPP55YJJJ?JJJJJJJJJJJJYYYYG##&@@&BPPPYGB###&@@@&#BGP5YJJJY5PGB###&##PGBG#@@@@@@@@@&&&BBP5YJJ?7!5PPPP5555555555    //
//    PPPPPPPGGPPGGGP5YYJJJJJJJJJJJJJJYYYYYYYYYP#&&#BGPGG5GBGGGBB#BGGGGP5YJJJY5PGB#&&&&#GPBGG#@@@@@@&&#G5J?J?7!777!!5PPPPPP55555555    //
//    PGGGGGPP555555YYJJJJJJJJYYYYYYYYYYY5555555PGGY7?YPYYYYJYPGPY?!!7??JJYYPGBB##&&&&#BGGGPG&@&&&&#BPJ7~:77!~~~!7!7PPPPPPPPPP55555    //
//    GGGGPP5YYYYJYYYJJJYYYYYYYYY55555555555PPPPPP55J??PGGGBBBBG5J?77?JJY5PGB#&&&&&&&#BGGGPG&@&##BG5J!~^:^7!~~!!77!JPPPPPPPPPPPPPPP    //
//    GGGP5YYYYYYYYYYYYYY555555555555PPPPPPPPPPGPY~JPJ?5G##BB#&BGP5YJYY5PB#&&&&@@&&&#GGPPPG&&#BGP5Y?!~^::!!~~!777!!5PPPPPPPPPPPPPPP    //
//    P5555YYYY5Y5555555555555PPPPPPPPPPPPPPGGGY7^:~YPJ7?PBGGGGY???JYYPGB#&&&@@@@&#BPP55P#&#BGP5Y?77!!~:~7!!~!!77~JGPPPPPPPPPPPPPPP    //
//    55555555555555555PPPPPPPPPPPPPPPPPGGGGG57^^^^:^55YY55YYJYYJ??J5GB#&&@@@@@@&BP555PB&&BGP5YJ?7!~^^::7!~!?J77!7PGPPPPPPPPPPPPPPP    //
//    5555555555PPPPPPPPPPPPPPPPPPPPGGGGGGGP?~~^^::..7BBBGGGPPGGGGPGB#&@@@@@@@&#P5Y5PB&&#BPY?7~^::::^^:!7!!!??77!5GGGGGGGGGGGGGGGPG    //
//    55PPPPPPPPPPPPPPPPPPPPPPPPGGGGGGGGGGJ~~~^^:....!B&&###########&&@@@@@@&B5JJY5G#&#G5?~:.. ..::^^:!77777?Y7!G#BGGGGGGGGGGGGGGGG    //
//    PPPPPPPPPPPPPPPPPPPPPGGGGGGGGGGGGGP7~!!^^::....^G&&&@&&&&&&&&&@@@@@@#PJ77JYP###GY!:    ...::^~^[email protected]@@@&&#BGGGGGGGGGGG    //
//    PPPPPPPPPPPPPPPPGGGGGGGGGGGGGGGGGY!~!~~^::::....?B&@@@@@@@@@@@@@@&BY!~~7J5B#P5J~.   ....::^~~^^77?YYJ??!5&&&&&&&@@@&&#BGGGGGG    //
//    PPPPPPPPPPPGGGGGGGGGGGGGGGGGGGGG?!!7~~~^:::......7P#@&@@@@@@@@@B57^:^~7J5BG7!^.     ...::^~!~^[email protected]@@@&&####&&@@@@&&#BG    //
//    PPPPPPPGGGGGGGGGGGGGGGGGGGGGGGG?!77~~~:::::::.....:7JJ5G##&@#PJ^...:~!?PG?::.      ....::^!!^[email protected]@@@@@@@##BBGB#&@@@@@@    //
//    GGGGGGGGGGGGGGGGGGGGGGGGGGGB#&J!7?!!!^^^:::::::::...:::^J!7#Y:....:^~?YJ^::.........::::^[email protected]@@@@@@@@@@&#&BBBB#&#&@    //
//    GGGGGGGGGGGGGGGGGGGGGGGGB&@@@Y!7?7~!~^^^~^~~~~^^^^:^^.:.:~~JG!:::::~77~.::........::::^~!7^7?7YYYY?~J#&&&@@@@@@&@@@@&&###BGB&    //
//    GGGGGGGGGGGGBBBBBB#####&@@@@B!7??!!!!!!!~~~~~^^^::::^:^:..:!PB7^^^~^:..^^:^:::::::::^^^!7~7???7JY?~YBGBBBB##&@@@@@@&@@&@B#&##    //
//    GGGGGGGGGGB#&#BBB##&&&#&@@@@?~!7~!!!~~~~^^^::::~!?J5GP5PGPJ~~PBJ!~. ..^^^^^::::^^^~~~~!!~!5YJ?7?7~Y&#B&&B#BBBB#&@@@@@@##&#&#&    //
//    GGGGGGGGGB#######&&@&&@#&@@5~!7~^^^^~~~!7?Y5GBB#@@&&@@&[email protected]#BB?Y?::!JGPJ!^^^~~^^:^^^~~~7!!!?5JYP?^YBB###&&@&@&#BBB#&@@&&#&&&&&    //
//    GGGGGGGGG#&&BGPPGB#&####@@#^~^^~!?Y5G#&@@@@&&&5P&&B&@@@GG&B#@G7YG#@@@@BB&B57~^^^^~~!!!775?~JYJ!^[email protected]@#BGGGB#&&@GG&##BB#BB&@&#&&    //
//    GGGGGGGB&&#G5G#&&&&&BP&#&@BYPB#&@@@@@@&#BGBB##GJ#&B&@@@GG&&B5G&&GG&&&[email protected]@@@@&B5?~~~!^!7J5Y~!P?:[email protected]@@@&####BB#B#&@&@&&###&##&#B    //
//    BBBBBB#@@&###&&#BB#&#G#B&@@@@@@@@@&#BGGB##B&B#&JB&#&@@@GG#&[email protected]&#B#@#&[email protected]@@@@@&&&&#GY?!~~!77~!:[email protected]@@@@@@&@@@&#BGB#&@&P#&&##&#GG    //
//    BBBBB#@@@@&#BP5PB#&#####@@@@@@&#BGBBB##[email protected]&###GP&#[email protected]@@@PG#&5B&&&@@&B&[email protected]@@@@@#&#&[email protected]@@#PJ!~^:[email protected]@&@&@@@@@@@@@@&#BB#&#&##&&&BGB    //
//    BBBBB&@@@@&GPB##BGB##B&[email protected]&#BGGB#B&#[email protected]@&&@@@@&5B&B#@@@@5B#&5#&B&&&&#&5#@@@@@@B#B&##@@@@@@@&[email protected]&G#B#@@@@@@@@@@@##B&##B#&#GGB##    //
//    BBBB#@@@@@@&&BPPGB&##B&#B#B##&&@#[email protected]&B&@@@@@@&B5#&G&@@@&YB&[email protected]@@&##Y#@@@@@@BBG&B&@&#@@@@@@@#BGBB#&@@@@@@@@@#B&@&#B&@###G5      //
//                                                                                                                                     //
//                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SHILL is ERC721Creator {
    constructor() ERC721Creator("SHILLSPEARE", "SHILL") {}
}