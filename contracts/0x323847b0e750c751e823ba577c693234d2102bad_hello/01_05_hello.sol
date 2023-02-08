// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: test
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    YYYYYYYYYYYYYYYYYY5555555555555555555555555YYYYYYYYYYYYYYYYY55555555555555555555555555555555PPPPPPPG    //
//    YYYYYYYYYYYYYYY555555555555555555555555555555YYYYYYYYYYYYY55555555555555555555555555555555PPPPPPPPPG    //
//    YYYYYYYYYYYYYYYYY55555555555555555555555555555555555555555555555555555555555555555555555PPPPPP5PP55P    //
//    YYYYYYYYYYYYYYY5YY55555555555555555555555555555555555555555555555555555555555555555555PPPPP5PP5PP55P    //
//    555Y5YYYYYYYYY555555555555555555555555555555555555555555555555555555555555555555555PPPPPPPP5PP55P555    //
//    YYYYYYYYYYYYYY555555555555555555555555555555555555555555555555555555555555555555PPPPPPPP5PP55P555555    //
//    YYYYYYYYYYYYYYYYYYYY55555555555555555555555555555555555555555555555555555YJY5PPPPPPPPPPP55P5555555YY    //
//    YYYYYYYYYYYYYYYYYYYYYYYYYY555555555555555555555555555555555555PPPPPPPPY?!^:!PPGPGPPPPPPP55P5555555YY    //
//    YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY5555Y??JY55555555555555555PPPPPPPPPP5J!^::^:~PPPPPPPPP55P5555555Y55YY    //
//    JJJJJJJJJJJJJJYYYYYYYYYYYYYYYYYYYY5J^:^^~7?Y5555555PPPPPPPPPPPPPPY7^::^^^^:~PGGPPPPPP55P5555555Y55YY    //
//    JJJJJJJJJJJJJJJJJJJJYYYYYYYYYYYYYYYY~:^:::^^~!?Y5555YYJJ??JYY55Y!::^::..:^:~PGGGPPPP555P5555555YY55Y    //
//    JJJJJJJJJJJJJJJJJJJJJJJJYYYYYYYYYYYY7:^:..::^::^~!!!!!!!!?5GBBBGY?~::::::^:~PGGGPPP5555PP55P555YY55Y    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJYYYYYYYYYJ:::..:::::~7Y5PGBB#BGGB######GJ!^:::::!PPGGPPP55555P5555Y5YY55Y    //
//    ???????????????JJJJJJJJJJJJJJJYYYYYYY!:::::::!YPPG###BPYJ?77?YPGGGBBGJ7~:::~5PPPPPP55555P5555Y55Y55Y    //
//    ???????????????????JJJJJJJJJJJJJYYYYYJ:::::~YGBGB##GY7!~~~~~~!!?YY5PGPYY?!^::7PPPPP55555P5555Y55Y55Y    //
//    ?????????????????????JJJJJJJJJJJJJYYY?^::^?5PGBB##GJ!~~~^^^^^^~~!JJJY5YYY5J7^.^5PPP55555P5555555Y55Y    //
//    ???????????????????????JJJJJJJJJJJJY?::^!JPGGBBB#G57!~^^^::::::^^!?JJYYYYPGG5! :YPP55555P5555555Y555    //
//    ??????7777777????????????JJJJJJJJJJJ^:^?5GB#GPBBBPJ7~~^^:::....:^~7?YPPPPGB#B57!YPP55555PP555555Y555    //
//    777777777777777???????????JJJJJJJJJ!:^JG#B&#B5GPPY7!~^^::::....::^!?YGBBBBB?77!!?PPP55555P55P5555555    //
//    77777777777777777??????????JJJJJJJJ??Y?Y#&&&#GPPG5YJ7!~^^^:::^~!7JYYPPBB#BB!::^~!??JY5555PP55555555P    //
//    77777777777777777????????????JJJJ?77?77JB&@@&##BB5PYYYJ?!~^:^~777!~^7JPB#PG!^::^^^~:~Y555PP55P55555P    //
//    77777???7777!77??JJYJJJJJJYYYYYJ7^:^~!!7P&&@###BB??7^~!7?!^:^^~!7???J5BGGPY!:::^^.^:.^J55PP55P55555P    //
//    77777??????J?77???JYYYYYY555PP5?^:::~~!~!P&&B#&&#P55?!~^!!^::::7Y5PPGG5?JYP?:..^^.:^..^J5PP55555555P    //
//    7777777??JJYYJ?7??JY55YYY55GBBY7^:::^~!~~!GBPGBBBG5?~::^!!^::::::::^^:::^!??:..:^:^^:::!5PPP5555555P    //
//    7777777????JJJJJJJJYY55555PB#B?7~:::^~~!~~JG5YJ?7~^::::!7!^:::::::...::^^~!~^:::^:^~:::75PPP5555555P    //
//    ?7777777???JY555555555PPPPPGBBY?7::^^~~!~~7G5J?!~^^::::!?7~::^^^^:::.:^^~!!~^::^^:^~::^J5PPP55555555    //
//    ??7777777?JJY5PGPPPPPPPPPGGGBBPYJ^^^^!~!~~7GG5Y?7~~^:::?YP5?!7!^:::::^^~!!7~^^:^~:~~:^?55PPP55555555    //
//    ?????77777?Y555PPPPPPPPGGGGBBB5Y5!~^^!~!!!?PBGP5J?!~^^^~7?J!^::::::~~~!!!!!~~^^!~~?~~?5555PP55555555    //
//    JJJ????????JY55PGGGBGBBBBBBB#B5JYY?!^7?!J?YP#BGGP5J?7!~^^^~!~~~~^^^^~!!!!7?!!!7?JPY?Y55555PPP5555555    //
//    5555Y55YJJJJJJ5PGGGBBB######&&PJ?J5PPGPJ5PPG##PPPPYJ????YY?????7?7~^^~!!~JGPPPGB#G55555555PPP55555Y5    //
//    JJJJJJJ????JJJJJYYYYYYY5555555YJJJJJYP5GB&&&&@GPP55YJ??JYYJ7!!!!7!~~~!!!7#@@@@@@#PP5555555PPP55555Y5    //
//    [email protected]@@@@@@[email protected]@@@&&&&GP5555555PPP55555YY    //
//    ????????????????????????JJJJJJJJJJJJY57B&@@@@@@@&BGPP5YJ?7777!~^^^~~!JP#&@@&&&&&&B555555555P555555YY    //
//    ????????????????????JJJJJJJJJJJJJJJJYJ?#&&&&&&&@@@@#GP5J?!~^^::^^~7YGBB&&@@&&&&&&&G55555555P555555YY    //
//    YYYYYYYYYYYYYYYYYYYYYYY?7YYYYYYYYYYYY!P#&##&#B&&@@@&#BGP5YJ?77??JYPBBG#&&@@&&&&&&&BP55Y5YY5PP55555YY    //
//    BBBBBBBBBBG5!!JGBBBBBGJ^^YBBBBBBBBGBJJ####BBGB#B&@@@#BBGGGGGGPP5JJPGPP&&&&&&&&#BGGBG5YYYYY5PP55555YY    //
//    BB###BBBBBG7~^^5BBBB#5^^:7BBBBBBBBBP7B##BBGGGGGB&@@&#BGGGGGP5J?7!7PGPB&&&&&###BGGPGGBPYY555PP55555YY    //
//    ######BBBBB?~^^?BBBB#?^^:?BB##BBBBB7GBBBGPPPPPG#@@&#BGGP5YJ?7!!~!?PGG&@&&&&##B###&##BBP5555PP55555YY    //
//    ###########J^^:~BBB#G~^::Y#B##BBB#JY#BGP5PP5PB&&#BGPP5Y?77!!!!!~!?JB#&&&&&&&&&###&&####G555PP555555Y    //
//    ###########J~^::5#B#J^^:^5#####B#5?BGP555PGB#&&BJJJJ??77!~~~~!~~!!!G&&&&&#&&&&&&&&&&&##&B55PPP55555Y    //
//    ###########J~^::?##P~^::^P######G?BG55PGB##&&&#BJ77JJ???777!^^!!7?JPB&&&&B#&&#&&&&&&&&&&&P????77???J    //
//    ##&&#######J~^::7##?^^::~G###BBB?PPPPGB#&&&&#55P5YG#BPJ7!?JJ?~!77!!?YG##&#GB#&&&&&&#&&&&&#J~~~~~~^^~    //
//    ##&&#######J^^::~BB!^^^^7YY5PGGYYPGGBB#&&&&@Y!77?YPB#PPY7?JYJ!!!~~!7?JG###BBGB##&####&&&&#G7~~~~^^^^    //
//    ##&&#######P~^^:~GJ~^:^^?J?J5GP5PG###&&&&&&B7!!!!!7?5GP7^!J7!~~~~~!!7?JG####&&#BBBBBB&&&&&#Y~~~^^^^^    //
//    ###########G~^^^~!^^::^^??J5BGGG####&&&&&#GJ^!!!!!~~7J~:::~~~~~~~~~~!!7JG&&&&&&#&&#GPB&&&&&5~~~^^^^^    //
//    #####PJ7?Y57^^^~!~^^^^^^7JPBBGB####&&&&#BGJ:~!!!~~~77^..^~^~~~~~~~~~~~~!JB#&&&&&&&#BBB#&&&#G!~^^^^^^    //
//    ####Y!~^:^^^^^^!!~~~~^^^!PBB##&####&##BGP?:.~~~~~~~!!!^:::^~~~!~~~~~~~~~7YG&&&&#&&B#B#&&&##B7~^^^^^^    //
//    ####Y!~^^^~~~~~7!~~!^^^^^?B####BGPBBBGGY~...~~~~~~~~!!^:..^!!!!!~~~~~~^^~!Y#&###&&##B#&&&##B7~~^^^^^    //
//    BBPY5?~~^^^~~~~~~~~^^^^^^^J##BBGGGGPP5?^...:~~~!7?7~::~!~~!7!!!!~~~~~~^^~:!B###&#&####&&##BG!~~~^^^^    //
//    BG7!?5?7!~~~~~^^^^^~~~~^^^~G#B###GY5Y7:....:~~!??777~~!??7!!77!!!~~~~^^^^ :YBB##B##B##&####Y!!~~~~~~    //
//    BB5J?YGGPY?77!!!!~~~^~~^^^~P##&#GYYJ!:......~!777?JYY?!!7????7!!!~~~~^^^: .7PGB#B##B#&&####?!!~~~~~~    //
//    ###G5J?J55J77J5P5YJ?!!~~~~~Y&&#G5J?~:.......~77?JYYYYYJ?7?YYJ?7!~~~~^^^^  .^YPG#####&#&##&B?!!~~~~~~    //
//    ####BPJ77??77PB#GGP5?7!!!!~?&#B5Y7^:....... !YYYYYYY5PP5J??YJ?7!!~~^^^^: ..:?5PB#&#B##&##&G?7!!~~~~^    //
//    #####BBG5Y?75BBBGYJ??77!!!~?#B5Y!:::........J5YYY5PPPPPP5J?YY?7!~~~^^^^. ...~Y5B#&#G###G&&5?7!!~~~~^    //
//    BB###BBGG5YJJJYPGPYJ?7777!!Y#PY!...........!YY5PPGPPPPPPPPYP5?7!~~^^^^. ....:JPG#&#BBBBB&#Y?7!!~~~^^    //
//    BBBBBBBG5J?77!77Y55J????7!!PGP7...........^JY5GGPPPPPPPPPPPG5?7!!~^^^^......:~PB###BBGB#&BY?7!!~~~^^    //
//    BB#####B5?7!!!!!!J55YJ?7!!7GP?::..........?555PGGPGPPPPPPPPGPJ7!!~^^^......::^YBB##BBGG#&GY?7!!~~~^^    //
//    #########PJ7!!!7!!?JJJ?7!!7B5^:::::......~55555PGGPGGPPPP5YPGJ?!!~~^:....:..::JGBB#GGGB##PJ?7!!~~^^^    //
//    #######&&#GPYJ?77!!!!!!!!!JB7^:::::::...:?Y55555PGGGGGP5J?7JBY?7!~~^.....:...:JGGGBGPGB#B5J77!~~~^^^    //
//    ######&&&&BP5YJ?7!!!~!!!!?GP!^^::::::::.~J?Y555555GGPYJ????7GPJ7!!^...:..:..:^YBGGGGGG#&BY?7!!~~~^^^    //
//    ##&&&&&&&&B5J?777!!!!!!7?5#5!~^^::::::::?JJ?Y555555YJ???JY?!JB5?!~:.::::::.::^YBPGBBGG#&GY?7!!~~~^^^    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract hello is ERC1155Creator {
    constructor() ERC1155Creator("test", "hello") {}
}