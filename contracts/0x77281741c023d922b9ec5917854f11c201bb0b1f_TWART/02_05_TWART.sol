// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tom Wüstenberg Art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//           ~PP^. .........                                  .:.:^^::::.~JJYY55PP5PPPPPPPPPP5:  ..^^^~!7?    //
//           ~P5^                                                  ......!JJYY555P5PPPPPPPPPGY:...:^^~~7?J    //
//           !P5^                                                      .:!JYY5555P55PGGGGGGPGJ^::::^~~!!7J    //
//          .7PY:                                                       .!?JY555555PPGGGPGPPP?^^~!~^:::^!5    //
//          .7PY:                                        .:::^:..       :7JYY55PPP5PGGGPGGPPP7!!77~..:^:~J    //
//          .?GJ.                                     ^7?Y5P555Y?!~^:.. .7JYJ555PP55GGGPGPPPY~~!!!!^:^~^7Y    //
//    !^^::::JG?.                         ..      .~7?5GGGBGGGGGGGGGGPY7~?YYY555PP5PGGGPGPGP?^^::^^::7J!YP    //
//    J7!?77?5GY~^~~:::::...        ..    ..     .!5GGBBBBBBBBBBBBBBB##BGPP5Y555555PGPGPGPGP!. ..   ^!7!J5    //
//    5YYYJ7J5GY77JJ!!JY55J?7!!~::::!~:...  .    .?5PGBBBBGGPPPPPPPGB######BP555PP5GP5GGPPG5^      .^^~7Y5    //
//    BBBBBGP5GJ!!7?7!?YPPYYYYJ?77!~?YJJ!^.^77!~~~?5P5555YJJJJJJYYY5PB###&&#B555PPPP55GGPPPJ.     ..^~:~Y7    //
//    BBBBBBGPPJ?7?J?77YP5JYYY?7777!?J?Y?^.75P5YY55PJ???????JJJJJYYY5GB####&#P55PPPP5PGPPPP!    ..^:77:!5!    //
//    BBBBBBGPGGGP5Y?77J55JYJYJ77??!J7~JJ^:!JY5PPGGY???JJ??JJJJJJJYYYPGBB###B555PPP5PPGPPP5:    .::~??^75~    //
//    GGGGGGGPGGGP5YY?77YPYYYYY?JY?!Y55GY::7?YJ5PPBJ?J?JJJ?JJJJYYYYYYY5GBBBBG555PPPPPGGPPP?.    ...^7::7Y^    //
//    YYYYYY5GGPYY5YYJ77Y5JYYYYJJY?75B#B?:^?YY!?5PB5PP5YJJY5PPGGPP555YYPGGP55555PPPPPGPPGP!. .....:~7..??:    //
//    555555PGGP55555Y?J5PPPP5J?JY77PB#B!:!5PY?JPGGPPGGP5JJ55PPPPP55YYY5PP555555PPPPPGPPG5^.......^^~::J?:    //
//    P55555PGG5YY555YJYPGGPPYYYYY??GB#G~:JBP55GBBB5JJYYYJYYYYYJJJJJYYY5PPY5555PPPGGGPPGGJ~!^:!77?J?JJJ5J:    //
//    BBGGPPGGG5J7!!?J?J555YJJJYYY?JB##5^^YGP5PGBBB5?JJJJYYYYYJ???JJY55PP5YYY5PPPPGGGPPGGJ7J?7?YY5PP5PPGJ:    //
//    #BGGPPGGGP55Y?!~!7??JJ?77???!7GBBJ:~Y5JJJJ?JJ?JJYYYY5P55YJJJJYY5PPPP555PPPPGGBGGGPP5JJ!7?5PPPPPGGG7:    //
//    YJJJ??5GGJ??J7~~~!77?JJ???7!^^7JY!:!55JJ?7????JY5PGGGGGPP5YYY55PPPP55PGGGGP5YY5GGGGPY?!?7!7J555PGP!^    //
//    ??J??JPBGJ??J7^::!?JJ777777!~~!77^:^~!~!!!7??77YPPPPPPPPPP555PPPPGP5GBBBGPY??Y5GP5P5J7~7!^~7JYJYP5~:    //
//    YYYJY5GBBJ!!7J!~~!?YJ!!!77777!~~^::::::^^^~~~~^JPYYPGP5YY55GPGGBBP55B##BBGGPYG#B55PP57!??7?JJYJY5Y^:    //
//    PPGPY5B#BJ!777!!!!7J7~~!YY????7?YYJ7!77?!!7!!?!JPPPPPPPPGGGB###BP5Y5B##BBB####BPGGPP5J77JJJ7JJ?J5?^^    //
//    YYGP5G###G5GGGGPPPGPPPPPBPP555Y?JJJJJJJY?777??77Y5GBBBB######BGP555YPGPGB######G5PGGGYJ77?Y55J7?YJ^~    //
//    ###BGBBB#BGBJ?7~~7Y!~!!JP5GGG5J7?JY5YYYJJ?!!?????7!JGBB##BBGP5555YJJ7~~?YPGB##BBBG5PPYJ??YGPJ7!!!7!!    //
//    GBP!~JPGP5YY!~~::7!....7~~Y!JJJJJJJYYJJJJJJJJJJJ?^^7YYY5555YYY55PJ^^^^^..:^!????J??55JJPGGPJ7!!!~7!7    //
//    JJ7!!~!?~:::!5GJ?Y~^!^^J!!?!JJJJJJYYYYY5555YYPP5?^~7JYYYYYYYYY55Y!^^^^::..:^~~~~~~~~!!?J?!!~~~~~!??5    //
//    YYYY5Y~!~!~^7G#GGJ~!77?5?7?JJJJYY5PP5YYY5PGG#&#GPYY55YYYYYYYYJ?!!~~~~~^^^^~~~~~~~~^^~~!!!~~!~^^!??!J    //
//    PPPPPPPPPPY?77?JP7!?5JJPYYYJJJJJJYY555BBGP5P&&#YP5555YY55YJ7!~~~!!!~~~~~~^~~~~~~^^~~~~!!!77?7?Y5GP55    //
//    BBBBBBBBGPY5PP55J77JY!!55YYJJYY5YJ??JYPG&&&&&&B55555555YJ7!!!!!!!!~~!!~~^~~~~~~^~~~~~~!!!!7J5GGGBB57    //
//    #BBBBBBBG55P55J7~!!!7?JYJJJJJYYJ7!!~~~J5P555PGPP5555YJ7!7777!!!!!!!~~~~~~~~~~~^~~~~~~~!!!!77PGG55Y?J    //
//    ###BBBBGPJ?~:..:!7JJYYYYYYYJJ?7!~!!~~~!!!!!!?5P55Y?7~^~!77!!!!!!!~~~~~~~~~~~~~~~~~~~~~!!!!77?JY5YYY5    //
//    ##BBBGGP5Y?~^~7?JJYYYYYYYYY7~~~~!!!~~!!~~!7?5P5Y?~^^^!!!!!!!!!!~~~~~~~~~~~~~!~~~~~~~~~!!!!7777Y55PGP    //
//    5PPGGPPPPJ~~J5YJYYYYYYYY5Y?!!!!!!!!!!!!!!~75P5J~^^^^!!!!!!!!~~~~~~~~~~~~~~!77~~~~~~~~!!!!!!7775GBGBB    //
//    GGGGGG5J~::?G5JJYYYYYYYYJJJ77!!!777!!7!!~~~J57^^^^~!~~~~~~~~~~~~~~~~~~~~~!7?!~~~~~~~~!!!!!!777YBBB#B    //
//    BGPPPY!^::^5G5YYYYYYYYJJYY?7!!!!7!77!!!!~~~~~^::^~~~~~~~~~~~~~~~~~~~~~~~!7?J!~~~~~~~~~~~!!!!!!?GBBGG    //
//    BGP5J^^^:::JG5YYYYYYYY?7??!!!~!!!!!!!~~~~~~:^^:^~~~~~~~~~~~~~~~~~~~~~~~!7?J7~~~~~~~~^^~~!!!!!~!P####    //
//    BGP5~^^^:::!PP55YYYYY?7!!~~~~~~~~~~~~~~~~~::::^~~~~~~~^^^^~~^^^~~~~~~~!7?J?~~~^~~~~^^^~!!!!!!~!P####    //
//    BBP7:^^^::^~7?JJYJ????Y?~~~~~~~~~~~~~~~~~:::::~~~~^^^^^^^^^^^^~~~~~~!!!7?J7~~^^~~~~^^^~!!!!!!!7B&###    //
//    BBG?^^^^^^~^^~~!!!77JY?~~~~~~~~~~~~~~~~~^::::^~~~~^^^^^^^^^^^~~~~~~!!!7??J7~^^^~~~~~~~~!!!!~~!?#&#&#    //
//    BBBY^^^^^^^^~~!!!!77?J!~^~~~~~~~~~~~~~~^::::^~~^^^^^^^^^^^^^~~~~~!!!!7??JJ7~^^^~~~~~^^~~!!!~~!J#&&#&    //
//    BBBGJ~::::^^~~!!!77?J57^^^^~~~~~~~~~~~^:.::^~~~^^^^^^^^^^^~~~~~~!!!!7??JJJ!~^^^~~^::...^~!!!~!Y&&&&&    //
//    BBBBBGY77?JY55555PPP5?~^^^^^^^^^^^^^~~::::^~~^^^^^^^^~~~^~~~~!!!!!!7??JJJ?~~^^^^:.    .^~!!!!!Y&&&&&    //
//    #BBBBBBBBBBBBBBBGY?!~~~^^^~~~^^^^^^^^::::^~~~^^^^^^~~~~~~~~!!!!!!!77?JJYJJ~~^^^^:    :^~!!!!!75&&&&&    //
//    #BBBBBBBBBBBBBG?~^^~~~~~~^^~~~^^^^^^:::^~~^^^^^^^^~~~~~~~!!!!!!!!!7??JYYJJ~~~^^^:...:^~~!!!7775&&&&&    //
//    #B######B###BY~^^^^^^~~^^^^^~~~~~^:::^^^^^^^^^^^^~~~~~!!!!!!!!!!!7?JJJYJYJ~~~~~~^^^~~~~!!!!777JGBBBB    //
//    ######B#BGPYJ~^^^^^::^^^^^^^^^^^^::^^^^^^^^^^^^~~~!!!!!!!!!~!!!!77?JJYYY5J~~~~~~~~~~~~~!!!!!!77YP5JJ    //
//    #BGPY?7!!~^::^!~^^~^^^^^^^^^^^::^^^^^^^^^~~~~!!!!!!!!!!!!!~!!7!!7?JYYYY5P5!~~~~~~~~~~~!!!!!!!!75Y!^~    //
//    J!~^:::::::::::~!^^~~~^^::::::^^^^^^^~~~!!!!!!!!!!!!!!!~~~~!7777?JJJYYY5GG7~~~~~~~~~~~!!!!!!!7Y57:^7    //
//    ::::::^:::::::::^~::~!^:::::^^^~~~~!!!!!!!!!!!!!!!~~~~~~~~!!777?????Y55G#BJ~~~~~~~~~~~~~!~~!7YPJ~^!J    //
//    ::::::^^^^^:::::::::^^^^::^^~~~~~~~~~~~~!!!!~~~~~~~~~~!!!!!77777777?J5G#BG?~~~^~~~~~~~~~~~!7?JY!~7JY    //
//    ::::::::^~~^^^::::.::^^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~!!!~~~!!!!!!!???5B#BGP?~~~~~~~~~~~~!!!!7777?JY55    //
//    ::::~7JYJ?7!!~~^^^^~^^^^~~~^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!!7?J5G&&BGGY!~^^^^~~~~~~!!7777777?5555    //
//    :~~!7?JYJJ77777777??~^^^~~~^^^^^^~~~~~~~~~~~~~~^^~~~~~~~~~~~!7J5GBB#BBGPP?^::::::::^^^~~!!77?JJYPP5Y    //
//    !?!!!7777777???J???777!~~~~~~~~~^^^^^^^^^^^^^^^^^^^^~~~~!!77?5##BGGGPPP55?^::::::::^^^^~~!!7YPPPP5YY    //
//    77?JYYYYYJJJ?????JJJJJ??!^^^~~!!!!!~~^^^^^^^^^^~~~~~!!!7777??YBGP555P555Y!:::::::::^^^~~~~!7?GP55YYY    //
//    JY5YJ??7777?????????JJYYY7^^^~!!!!!!777!!~^^^~~~!!!!!!!!!!77J5P55YYYYYYY?^:::::::^^^^^~~~!!7JG55YYJJ    //
//    5J???7!!!!!!!77777??JJ??JJ!^^^~!!!!!!7?JJJ?7!~~~~!!!!!!!~!7J55YYYJJJJYYY??JJJJ???777!!!!!!!?5PYYJJJJ    //
//    ?7777!!!!!!!!!7!77777??JJYJ?!~~~!7!!!77??JYYJ?7~~~^~~~~~!7JYYJJJJJJJJJYYY5P5555PPPPPPGGP5YPPPYJJJJJJ    //
//    YYYYYYYYJJ?7!!7777777????JY55J??JYYJJ?????JJY555Y?!^^~!!?YYJJJJJJJJJJJYY5PP555PPPPPPGB&&BGGPYJJJJJJJ    //
//    YYYYY5555555Y?7777?????JJJJJ5P5J??????????JYPB&B5J??77?J5YJJJJJJJJJJJJYY5PPPPPPPPPGGB#&BPP5YJJJJJJJJ    //
//    5555555PPPPP55Y??????JJJJJJYYYPPJJ????????J5G#&PJJ??JY555YJJJJJJJJJJJJY5PPPPPPPPPGGGB&#P5YJJJJJJJJJJ    //
//    PPPPPPPPPPPPPPPY???JJYYJJJJYYYY5PYJJJJ??JJJYP#@#P555PPPP5YYYJJJJJJJJJYY5PPPPPPPPPGGB&#G5YJJJJJJJJJJJ    //
//    PPPPPPPPPPPPPPPPY?JJJYYJJJYYY55Y5PYJJJJJJJJ5G&@@#PG#&BGP555YYYJJJ??JJYYPPPPPPPGGGGB##G5YJJJJJJJJJJY5    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TWART is ERC721Creator {
    constructor() ERC721Creator(unicode"Tom Wüstenberg Art", "TWART") {}
}