// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shiba Sequoia Forest Foundry
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                     //
//                                                                                                                                     //
//    Result                                                                                                                           //
//    &&&&&&&&########BBGGGGGGPPPPPPPPPP5555555PPGB#&&&&&&&##########P&@&#&&&&##########################BBBBBBBBBBBBBBBBBB####&&&&&    //
//    &&&&&&&&########BBGGGGGPPPPPPPPPPP5555YY55PPGB&&&&&&&##########P&@&#&&&&###BGB##################BBBBBBBBBBBBBBGGBBBB####&&&&&    //
//    &&&&&&&&########BBGGGGGPPP555555555YYYYYYY55GBB#BBBB#GPBP5G####P!!JJ?7755JYGY?5G#############BBBBBBGGBBBGBBBBBBBBBBB###&&&&&&    //
//    &&&&&&&&&########BGGGGGPPP55555Y555YYYYYJJYY55YYYY?7J7?J?!^Y###!...^~:.:!7!77!^YBPGGPGGPPBBBBBBBBBGGGGGGGGBBBBBBBBB####&&&&&&    //
//    &&&&&&&&#########BGGGGGPPP555YYYYYYYYYJJJYYYYJJP?~!7~~7?7!?77J5~..:^~7!^!?!:^~^?~!!~.:!7:~BBB##BBBGGGGGGGGGBBBBBBBB####&&&&&&    //
//    &&&&&&&&#########BBGGGGPPP55YYYYYYYJJYYY55YYJJYJ!!77?Y7!7~~~^~^^^!?!!5JJ7YYYJ?!~.....:^!?5#BBGYBP5GBGGGGGGGGGBBBBBB####&&&&&&    //
//    &&&&&&&&&########BBGGGPPP555YYYYJJJJYJ?JJ?J7?^~:^!^:^!!~!PGJYY7?7YP5YJJJ?77YBB5P?!?!.  :!J5!7^~55??5PGGGGGGGGGGGGBB###&&&&&&&    //
//    &&&&&&&&&########BBGGGPPP55YYYYYJJJJJJ???!?7!:  ~7J?5GBJ7#BGPYJY7~~~~~^:~:.!B###BGY~.::??7^.:^~?YY?5GGGBGGGGGGGBBBB###&&&&&&&    //
//    &&&&&&&&&########BBGGGPPP55YYYYYYYYJJJJ??777!^^?B&&&&&&G!!^^^~^^^!~^~!YJYPY5555GBP!!:7J7:7YPY:^YG5P5PPYPGBBGBGBBBBB###&&&&&&&    //
//    &&&&&&&&#########BBGGGPPP55YYYJYJYJY?JJ5~^^~~7JJG&######G7 .^G#[email protected]~: ..7~~~!?YBBBB^~JJ7!7JJ7^~!:~YJYJ~?JPBBBBBB####&&&&&&&&    //
//    &&&&&&&&&########BBGGPPPP5YYYJJJ??7!^!?7^~!^!??JP&#######B?^.^PP?5G!~5~.?5?7PY7YGPP7.?PY~~!~^:^.  .!!!P5JJGBBBBBB####&&&@&&&&    //
//    &&&&&&&&&&#######BBGGPPP55YYY555555J?~?7J!7?7!JJY#&&&&&&&##?^:~?~7BG!.:.::::^^^:....:?GGGGBBPJY7~7JJGGGGBBGGBBBBB###&&&&@&&&&    //
//    &&&&&&&&&&#######BBGGPPPPPP5YPG5YY5Y55Y55YJ??^?Y5GG5JJYPGJ?^ .^:JPB7~!JP5~~!~7?!:::^77YYPPPPGBBGPPPPGGGPPPGGGGGBB###&&&&@&&&&    //
//    &&&&&&&&&&&#######BBGPGP55P5PPP55J7YJ!7!~^.:77J777!!~!:^~^^:::::~^^^~?5Y7?YJJGP555P5JYBG7!7~!75PYJJ55PGPPGGGGGGBBB##&&&@@&&&&    //
//    &&&&&&&&&&&&######BBGPPPYYYJ?7??77777J??~:.~?JY!~~::~?!JY?77!7!7??YYJJYJ777Y5PY5PGGGGGBG?~7J7?7?!!!??!5PPGGPPPGGB##&&&&@@&&&&    //
//    &&&&&&&&&&&&&#####BB55PY5J?^~???7!77JJJ??7!~~!!~!!77~^!?YY57YJYY5555YYP5J~.^PPPP5YYY?J?!JYP5JY5P55PPPPPGG57???Y5PG&&&&@@@&&&&    //
//    &&&&&&&&&&&&&#####BBPYYJ?JY?JJJJJJJJJJJ?????7?J?JYG#P^^JBG#GGJ?7Y5##5YYJ57!7Y55GP555~::.:^:.!Y55Y?!~777??7!!?J?YG5G&&&@@@&&&&    //
//    &&&&&&&&&&&&&&#####BBGPP55YYJJ?JJJJJJJJJ????????JY77?!!YPY5YYJ!YYYBGYJ?55YJPG5YG55PGPPJ?J7~: .^7?~!:~7J?7!75PPBB###&&@@@@&&&&    //
//    &&&&&&&&&&&&&&&###BBPYJ7~!!:^^^~JJYYYYYYYJJJJJJ?7?7^!YYY55JJYYGGJYP&5GPGBG5PJ^^:^^7?5J:::^:.    :^7JPY~!?JJ55PB##&&&&@@@@&&&&    //
//    &&&&&&&&&&&&&&&&BYJJ7~^:^7?!~!JJYYJY5JY555YYJ?!:.^~^~7JPGGB5P##BJ5P&G##BBGGJ^:!Y5J7^:^~~. ~!:.^~~YP55J^???JPP55G#&&&@@@@@&&&&    //
//    &&&&&&&&&&&&&&&GPYP?7!^^7?!::.:!JY?YYJJ5Y?7J!^^~~!77~^~!YGB###&PYPG&B##BPY!::YBGBBBBPPGG^ :J:^7777~~JJ7GBGYJYG5PGB#B&@@@@&&&&    //
//    &&&&&&&&&&&&&&&GYYYJ~::~^~7~:^!!!?7~!^^^!JY?~^!?77Y5PP7:.:^!?5GY5GB#5Y7!~!^.^PGBBBBBBBBBP7J7YPPPP5Y5PP5GP77~JY??YP5PB#&@@&&&&    //
//    &&&&&&&&&&&&&&&B5G?JYJYGGPPP555555J~. :^~~~~~J5Y???7!YBY~?J!~7?!YP!~!JJ5PGPYPGBBBBBBBBBBBBGG7?YPPPPPPPPPJ7^:!7??J5JYBB#&@&&&&    //
//    &&&&&&&&&&&&&&&&##BP###BBGPP55555Y!~JYJYY~7~?JYJ7?77!?B&#&&&#Y?JY775#&&&#BBBBBBBBBB####BBBBB5^~PGPPPPPY:.:~^:JJYP&&&&&&@@&&&&    //
//    &&&&&&&&&&&&&BPGJY5PB###BBGPPPP55J^!JYYYJ7!!?YJ7!!7!!~7Y!JJY#&[email protected]#&&&###BB###############BJ~75PPY!7~..7~77J5JP&@@@@@@@&&&&    //
//    &&&&&&&&&&&GG5555YY5BBGPPPPPPP55J~!~^!~^!7!7?Y?7JYJJ?!77??Y5P&#JY5&@#&&&&#####BG########BBBPPPY?5G5^^?Y77J?Y?YJ5B&@@@@@@@&&&&    //
//    &&&&&&&&&BGBGGGGB55PPY?Y?775GP55Y?!. ~?~~~7YJYJJ?7~~~?JJ!J?5B&B5PG#@&&&&&&##PPJ75P55BG5JYYJ?Y5PGBG5J5YYGPGBG?5B5PBP&@@@@@&&&&    //
//    &&&&@@@@&#GPPGB#BP5PGP5J7?7J5PPP5J~:^77?YY55JJ?!:  .!5P##BB#&&G!JYGP&&&&&&&PJYYPG55P5Y5PP#GGGGPPPGPPPYPBG??7^~JY?P5B&@@@@&&&&    //
//    &&&&@@@@@&GBBBGPP5BGYGGG5!PBBPJ5J!^.. .??J?77!!7!~!JYJJGB&@&&&&7!?P!P&&&&&&#B#####GB###&#&&##BBB5JY5PPPGG!.~?7BP?5GB#&@@@&&&&    //
//    &&&&@@@&##B#[email protected]&#&#GG5J?5Y7J5!!^.^??7JJ?5PP5PGGGPPPGB&@&&&@5^J7!?#&&&&&&&&&&&&&&&&&#GGGPPGGGP555GBPGBBB7^7??J5PYG5P&@&&&&    //
//    &&&&@@@&B##BGBB#B&@@@@BPPPPPJ?55JGG5YPYPYYYPBGPPGP5555B&@@@@@&@B^. .:Y&&&&&&&&&&&&&&&&Y5GG5GBBB#BGP#&#GB###YPPJB#G&&@&@@@&&&&    //
//    &&&&@@@@@@@&&&@@@@@@@@&&&&&&BBBBPGBBBG5GGGPGGPPP55YYY5B&@@@@@@@&G?   ^G&&&&&&&&&&&&&&&5G##&&&#B##BB##BB####&&&#&&&&@@@@@@&&&&    //
//    &&&&@@@@@@@@@@@@@@@@@@@@@&@@&&&####BBBBBBGGPPPPPP55555G&@@@@@@@@B&~:~?B&@@&&&&&&&&&&&&@&&@&&##############&&&&&@@@@@@@@@@&&&&    //
//    &&&&@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&######BBGGBGGGPP555P&@@@@@@@&Y7~!PB#&@@@@@@@@@@@@@@@@@@@&&###########&&&&&&@@@@@@@@@@@&&&&    //
//    &&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&####BBBBGGPPP#@@@@@#~...7YBB&@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@&&&&    //
//    &&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&###B####BGGB&&&&&Y    ~Y#&&&&&#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@&&&&    //
//    &&&&@@@@@@@@@@&&&&&&&&&&&&&&&&#############BBBBBBBBBBBBBBBBGBP^:..?5P#BB#B#############&##&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@&&&&    //
//    &&&&@@@@@@@&&&&&&&&&&&&&&&###&&&&#########BBBBBBBBBBBBGGBGGGG?^?JPB#GPB##BBB##############&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@&&&&    //
//    &&&&@@@@@@@&&&&&&&&&&&&&&&#&&&&&&&&#######BB#BBBB#BGGGP5P5JJJ~JB##G#G5P5YP5##BG########&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@&&&&    //
//    &&&&@@@@&&&&&&&&&&&&&&&&&&&&#&&&&&########BBBB#BBGGGPPGG##J~:?GB#&&GBGJJY55GB#B#&&########&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&#####&&&&#&&&&&#######BBGBGPGBBBBB#GY?J7G#GJG&BPYG#&&#5B&&&#######B#&#&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&#&&&&&&&&&&#########BBBBGBG5GGBPY?5###P5PG#&#P5&&&&&#5##BG&#########&##&&&&&&&&&&&&&&&&&&&&@@@@@@@&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#############BGBBBBBPG5YGB#####&GJ55PYY#&&&&&&&BBBG###B##########&&&&&&&&&&&&&&&&&&&&&@@@@@&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&#########&#####BBBBBB##BBBJ#&&&&&&&&&BB&&Y^B&&########GPBGBBBBB######&&&&&&&&&&&&&&&&&&&&&@@@@@&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&#&&&&&####&&&##BBBBBBBBPGGG#&####&&&#5PG#&G?JGGPPPPPP5GGPP#&##BB#B#####&&&&&&&&&&&&&&&&&&&&&@@@@&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&#&&&&&&#&&&#&&##GGGBB#&#5&&&###BGPGB#57##GG##BB##&&&#B####BGB##B########&&&&&&&&&&&&&&&&&&&&&@@@@&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&##&&#####BBGB###BBGB#BBBBPYGGGPPP5G#&@@@@@@&&&G5#&&&&&##B##B##B##B###&&&&&&&&&&&&&&&&&&&&&@@&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&#&&##&&&&&#BB#BPGGBBBG###Y#&&&&&&&&#GB&&&&&###&PBGGBBBBBBB#B####B#B#&&&&&&&&&&&&&&&&&&&&@@@@&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&####BBB###BB####P####&&&&&&#YBB#####BGB##BGBBPPBB##BGBB#######&&&&&&&&&&&&&&&&&@&@@&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&############BBBBBBG&#GBB#BB###PG#&BGBB##GG#BGB#GBBGGGBBBBB########&&&&&&&&&&&&&&&&&&&&@&&&&    //
//    &&&&&&@&&&&&&&&&&&&&&&&&&&&&&&&#######BBBBBBBBBBB#BP#BBBBB#BBBBB5#BGG#GGBB##B##B##BGGBB#BBBBBB#######&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&@&&&&&&&&&&&&&&&&&&&&&&&&&&######BBBBBBBBB#BBG#BBBB#BBBBGBBBGGGBGBB#BBB######B#BBBBBBBBBBB######&&&&&&&&&&&&&&&&&&&@@&&&&    //
//    &&&&@@@@@@&&&&&&&&&&&&&&&&&&&#####BBBBBBBBBBBBBBB##BB##BBBGBPBG##BGGBBBBBBBBBB#BB#B##BBBB##BB####&#&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&@@@@@@@@@@&&&&&&&&&&&&&&&#######BBBBBBBBBBBBBBBBBB##BBBBBB#GBGBGGGGBBBBBBBBBBBBBBBBBBB#BBB###&&#&&&&&&&&&                    //
//                                                                                                                                     //
//                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SSFF is ERC721Creator {
    constructor() ERC721Creator("Shiba Sequoia Forest Foundry", "SSFF") {}
}