// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mid Journal
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    TEXT-IMAGE.com                                                                                          //
//    mainconvertsampleshelpabout                                                                             //
//    Result                                                                                                  //
//    ###BY~YGP?~7PB#####&&&&&&&&&&&&&&&&&&&&&&&&##&###########&&&&&&&&&&&&&&&&&&&&&###B##5GP?^~Y5Y^~5BB#&    //
//    ##BBP?~YP5!~?GB######&&&&&&&&&&&&&&&&&&&####BP5YJJJY5PB#####&&&&&&&&&&&&&&#####BBBBG5PJ^:J55!^?5BB##    //
//    ###BGY!~Y5Y~~YGBB#####&&&&&&&&&&&&&&&&####P???Y55PP5Y?7?P#######&&&&&&&&######BBBBBYP5!:!Y57:7J5BB##    //
//    ###BG5J~~Y5J^!5GGBBB###&&&&&&&&&&&&#####G??5B#BPBPG###GY7?G##################BBBGGP5P?:^YY?:~?J5BB##    //
//    ###BBPY?~!YY7^7PGGBBB#####&&&&&&&&####B5!YB#BG5:J~!GB###GY!PBB############BBBBBGGGPPY~:?YJ^^7JYPBB##    //
//    ####GP5J7^!JJ~^J55GGBB######&&#######BP!YB##J~::~!~^^!G##BJ7GGBBB#######BBBBBBGGPPP57:!JJ~:7?Y5PB###    //
//    &###GYPY?!:!J?^^J5PGGBB###########BBBG?7G####J::YBGJ::J###P!YPGGBBBBBBBBBBBGBGGPPYY?:^??~:!?J5J5####    //
//    &&##GJPPY7!:!?7:~JPPGGBBBBB####BBBBBGG7?B####Y::~!!^::?B##G!JPPGGBBBBBBBGGGGGGP55Y?^:7?!:~7J557Y####    //
//    &&&&5JGG5J7~:!?~:!Y5PGGBBBBBBBBBBBBBGG?7B####Y::JGPP!::?##P!YPPGGBBBBBBGGGGPGG55YJ!.~7!:^7?YPP7J####    //
//    &&&&YPBBG5J7~:!!^:7Y5PGGGGGBBBBBBBBGGG5~5###B7::!J?7^:~PBG?7PPGGGGGGGGGGGPPPPP5YY7::!!::!?Y5PGY?####    //
//    &&&#JPBBGPY?7^:!!:^?Y5PPGGGGGGGGGGGGGPPJ!PB#P?7:7^~JY5GBG?!5PPPGGGGGGPPPPPP5PP5Y?^.~!::~7J5PPPY7PGBB    //
//    PBY?JPBBGGPY?7^^7!:^JYPPPPPGGGGGGGGGGPPPJ!JPBBG?PY5BBBGY775PPPGGGGPPPPPPPP5555YJ!.^!^:~!?Y5PPGY!Y!?J    //
//    GJ7BJP#BBGG5YJ?~7!~^?JYY5PPPPPPPGGGPPPP555?7?Y5PGGPPYJ77J55PPPPPPPPPPP55555YYYJ?~^~!^!7?Y5PPPGY?#J!7    //
//    5J5&JP#BBBGP55J!!~^^^~~75555PPPPPPPPPPPP5555YJ???????JY5555PPPPPPPP55555YYYJ!~~~^~~~!?JJY5PPPGY?#5~J    //
//    PJP&JP#BBBGGP5Y7~:::::^?Y555555PPPPPPPPP5555555YYYYY555555555555555555YYYYY?~::::::~7JYY5PPPPGY?#P~7    //
//    P?G&JP##BBBGPPY7!^:.:^^!JYYYY55555555P55555555555Y555555555555555555YYYYJJJ7^^:.::^7?JYY5PPPGGY?#G!?    //
//    P?G&?P##BBBGGPY77!~^.^^^!?JYYYYY5555555555555555555555555555555YYYYYYYJJJJ7^^^::^~!7?JY55PPPGGY?#G!7    //
//    PJG&?P###BBBGP577?!~:.^^^!?JJJJJYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJJJJJJJJ????~:^:.^~!!?JY55PPPGGGY?#G!7    //
//    YJ5&?P###BBBGG577J?!~::^::!??!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!77~:::.^~7!~?JY5PPPGGGGY?#5~7    //
//    &G5&?P####BBBGP7!JJ?!~::^::!77~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~7!:::.:~!?7~?Y55PPGGGGBY?#JY5    //
//    &@@&JG&&####BBP7!YYJ?!~::^::!7!~!!!!!!!!!!!7J5PP5Y7!!!!!!!!!!!!!!!!!~~!!:.:::~!7??~JY5PPPGGGGB5J&#&&    //
//    @@&@JG&&&####BP7~YYJJ?!~^::::~77???JJJJJJPB&@@@@@@&BY?JJJJJJJJJJJ????7!^::::~!7?J?~J55PPGGGGGG5J&&&&    //
//    @@@@J5BB#&####G7~JJYJ?7!~::.::!77???J?JP#&&@@@@&&@@@&PJJJJJJJJJJ????7!^.:.:^!7??J?~Y5PPPPJ???JJJ&&&&    //
//    @@@@JJP5YP####G!~77YJJ?!~~^:.::~!77??JB&&&@&&&&&&@@@@&5???????????777~::::^~!7??J?~Y5PPP?!7?7!!J&&&&    //
//    @@@@J?PBG5P###G!!77??J?7!!!^:.:^~!!!J#B55B&&&&@@@@@@@@&J????????777!~^::.^~~77?JJ?~555PP7!?YY?~J&&&&    //
//    @@@@J7JPG5P###G!!77!!?J7!77!~^:::^~~5#???J5GB&@@@&#@@@@P7???77777!!!^.:::~~!7?JJ?~~5PPPP7!!?JJ?Y&&&&    //
//    @@@@J7J5YP####G!!7!!77J77??7~^::::^^G&?7Y5YYY5G&&G5#@@@#777777!!!!~~:..:^~~!??JJ?7~5PPGP7!7?7!7Y&&&&    //
//    @@@@J7YG5P&#&#G!7!7!7?Y77J?7!^^^::::[email protected]#@@@@P!!!!!!~~~~^:.:^[email protected]&&&    //
//    @@@@J7GB55&#&&B777!???Y??YJ?7~~^^:::^J#[email protected]@@@@@B57~~~~^^:::^[email protected]&&&    //
//    @@@@J?P5P#&#&&B77!7?7?Y??YYJ7~~~^^::::!YYJ?JJY55P#G#@@@@&&&G!^^^^::.:^~!7!!?J7!?7^^GBBBGJY777JJY&&&&    //
//    @@@@Y5##&&&#&&B??JJ??Y5??YYJ7^~~^^::::^7Y5YJJY5P#BPG#@@&&@@B!^^:::::^~!7777?J7!77:^G#BBGJPPPPPYY&&&&    //
//    @@@@YP&&&&&###B??????Y5??7!??~^~^^^::::~J5YYY5B#G55PB&@@@@B?:::::::^^~7??77JY?!?7~~B##BBJYYJJJ?J&&&&    //
//    @@@@Y5&&&&####B??7????YJ:::.7?~~^^^^^::::~!!~?P5YY5PPB&Y?7^:::::::^^^~??J77JY?!?J?!B###BJ7?77!!Y&&&&    //
//    @@@@YYGGGB####B??7!!?Y5J^:::??~~^^^^^^::^~7YBBYYYY5PB&@#!..::::::^^^^!?JJ??J5?!??7!B###BJJJ7??!Y&&&&    //
//    @@@@YJ5YGPB###B??77!JYGP5JJYPB!~^^^^^^YGB#@@&B5YY5P#@@@B#PJ!^:.:^^^^~!JJY??J5J!7!!!B###BYJ!!77!Y&&&&    //
//    @@@@Y?YYGPB###G??!!!JYPB&[email protected]~~~~^~B&#&@&BPPBP5P#[email protected]@@&G5!^^^^~!JYY??Y5J77!~!B###BJJ77!7!Y&&&&    //
//    @&&@Y?YYPPB###[email protected]&##@#~~~~~^[email protected]&@BGP5555P&&?7Y5Y5#@@@@@G^^^~~7JYY??Y5J77!~!B##BBJJ????7Y&&&&    //
//    @&&@Y?5YP5B#BBG7?7!7J?Y75&@@@5^~~~^?##@&G55555PG&@#7~7?P#@&&&@@#^^^~~7JYY??Y5J77!~!B#BBGYJ??77!Y&#&&    //
//    @&&@[email protected]@@#J~~^~P&@[email protected]@@#5YG5#@&&&&@@G^^~~~7JYY??Y5J77!!!BBBBGY5JJ??!Y###&    //
//    &&&&Y?YJ55BBBBG7777??JY75BB&##B~^~5#&B?:^!^[email protected]@#BGGBB&@@&&&@@@Y^^~~~7JYY??J5J7777!GBBBGYGGGPPJY####    //
//    &&&&Y?5Y5YBBBBG7777?JJY7Y#GB#@@?^JG#&5?:^!~!G&#BBB#&#&&&@@&&&@&J^~~~~7JJY??JYJ!~!~!GBBBGYP5YJJ?Y####    //
//    &&&&Y?5YYYBBBBG77??7JJJ7~Y&@@@@#[email protected]#&@@&&&&@@@&&@@#7^~~~~!?JJ?7JY?~!7!!GBBGGJ?7777!J####    //
//    &&&&Y?YJ5YBBBBG77??!JJJ7!7P#&@@@55&&#&BBBPG##&@@@@&&&@@@@@@@&@#!^~~~~!??J77JY?!~!~!GBGGGJJ!^^~~J####    //
//    &&&&Y?YJ5YBBBBG7777!JJJ77?YB#&@@&BG&@##&BG&@@&&&&&&&@@@@@@@&&@B^^^~~~!???77?J?7!!~!GBGGGJJ7^~^^J#B##    //
//    &&&&Y?JJYYGBBBG!77!??JJ77?75##&@@#&[email protected]@&[email protected]&&&&&&&&@@@@@@@@&&&&#~^^~~~!77?77?J?777!!GGGGGJ?7^^::J#B##    //
//    &&&&Y?5YYJGBBBG!!7777??77?775##@@&@#&@&[email protected]@@@@@@&@@@@@@#&@@&&@B^^^~~~!77777?J7!~!!!GGGGGJ?!^~:^Y#B##    //
//    &&&&Y7YJYJGBBBG7!!!!!7?77777!Y&#&@@&#@@@#@@@@@@@@@@@@@P~#@&&&@G^^^^~~!777!7??7~^^~!GGGGGJ?!!!7!J#B##    //
//    &&&&[email protected]@@@@&@&#B&@@@@@@@@@@@B!:[email protected]@#&@&!^^^~~!!77!77?7~^^:~GBGGGJ?JYYJ7Y####    //
//    &&&&Y7YJYYGBBBG7!77~!7?77777!~^[email protected]@@@@@&BB&&@@@@@@&&@B^::[email protected]&&&@&!^^~~~!!77!77?7~:^:~GBGGG5J7777!Y####    //
//    &&&&YJPPPPBBBBG7!!!777?77777!!~^?PBP#@@&#@@&&&&&&@@@G:^:[email protected]@@@@@G~^~~~!!77!77?7!~!!!GBBBGGGP555?Y####    //
//    &&&&YJPBBBBBBBG?7???!??77777!!~~^^^^#@@[email protected]@@&&##&&&@G^^:[email protected]@@@@@&~^~~~!!77!77?7!!!!7GBBBBBBBBGBJY###&    //
//    &&&&5JJGBBBBBBGJ7777?JJ77?777!~~~~^JG&&[email protected]@@&BB&&&@&&5:::[email protected]&&&@@Y^~~~!!7777????????GBBBBBBBBBBY5&#&&    //
//    &&&&55###BBBBBBYJYYYYYJ???777!~~~^7BG&&[email protected]@@&P&@@@@&&#?::~#@&&&@@J~~~!!7777?JJJYYYJGBBBBBBBBBB55&&&&    //
//    &&&&PG######[email protected]#[email protected]@@@#[email protected]@&&@@@@Y^^7&@@#&@&7~!!!7777?JJYYYYYBBB########PP&&&&    //
//    &&&&GG########B5YPPPP55J????7!!~~5&G#@##[email protected]@@@@[email protected]@@@@@@@J^^?&@&@@@#!~!!7777?JYYY5YYGB#########GG&&&&    //
//    &&&&BB########B55GGGPP5J????77!~J&&[email protected]@B#B&@@@@@P&@@@@@@@&!^^[email protected]&&@@@G~!!7777?JYY555YG##########GB&&&&    //
//    @&&&BG########BP5GGGGPPY?J???7!~?G#&@@B&B&@@@@@#[email protected]@@&###[email protected]@&&&@P~!!7!7?JY5555YG#########BPB&&&&    //
//    @&&#B5#########P5GGGGGPYJJJ??7!~7B#&&@G&&[email protected]@@@@@BB###&&@&[email protected]&&&&@5~!!!7?YY5555YG#########P5B#&&&    //
//    @@&&&P#&&######[email protected]@&&#[email protected]@########&&@@@@@@#!~~~^[email protected]@&@@@5~!!7JYY55PP5G#########GB&&&&&    //
//    @@@&&G#&&&&####[email protected]@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@5!!7JY555P55G#########BB&&&&&    //
//    @@@@&B#&&&&&&&#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@&!!!~!&@@@@@#G7!7JY55PPPPB########&B#&&&&@    //
//    @@@@&###&&&&&&&BGB#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@?!!!!GBB#GBJ~!!7JY55PPPPB####&&&&###&&&&@    //
//    @@@@&&#&&&&&&&&#GB###BBG555YJ?7!P&@@@@@@@@@@@@@@@@@@@@@@@@&?~~~~~~!###&Y^~7?Y55PPPPB###&&&&&##&&&&&@    //
//    @@@@&&&&&&&&&&&#G#####BG5YJ7!!!~5&@@@@@@@&&&&&&@@@@@@@@@&&#!^^^^^^^[email protected]@@@Y^~!?JY5PPGB##&&&&&&#&&&&@@@    //
//    @@@@@&&&&&&&&&&#B###BGP5J?7!!!~^J&&&&&&&&&&&&&&&&&&&@@@&&&5^^^^^^^^[email protected]@@@@Y~!!7?JYPGB#&&&&&&&#&&&@@@@    //
//    @@@@@&&&&&&&&&&#BBBGP55JJ?7!!~~~7&&&&&&&&&&&&&&&&&&&&&&&#B!^^^^^^^^^[email protected]#P&@Y~!77?YPGB#&&&&&&&&&&&@@@@    //
//    @@@@@&&&&&&&&&&#BGGPP5YJJ?7!!~~~~B&&&&&&&######&&&&&&&&#BJ^^^^^^^~~^^Y&!Y&J!77??JYPGB####&&&#&&&@@@@    //
//    @@@@@&&######BBGGGGPP5YJ??7!!~~~^P&&######B############G5^^^^^^^^^~^^^YJG57!77??JY55PGBBBBB##&&&@@@@    //
//    @@@@@&######BBBBBBGGP5YJ??7!!~~~^?&##BBGGGPGGGGGGBBBBBG57:::^^^^^^^^~!~7?~~!!7??JY5PPGGBBB##&&&@@@@@    //
//    @@@@@&&&&##BBBBBBBGGGP5YJ?77!!~~~~B#BG?777777??????JJJJ7~~^::^^^^^^~^^^~~~!!!7?J55PPGGGBBB#&&&@@@@@@    //
//    @@@@@@&&&&&######BBBGP5YJ?77!!~~~^J#BP!~~~~~!!!!!!~~~~~~~~~^:^^^^^^^~^^^!!!!777?5PPGGBBB###&&@@@@@@@    //
//    @@@@@&&&&&&&&&####BBGP5YJJ?7!!!~~~~B#BP5YJJ??????777???~^^::::^^^^^^~~~~~7!!777?JPGBBB####&&&&&@@@@@    //
//    @@@@&&&@&&&&&&&&&&#BGGPP5YJ?77!!!~~J##BBBGPGGGGGBBBBBBP^::::^^^^^^^^~!~!!!?77??JY5GBBB####&&&&&&@@@@    //
//    @@@&&&&@@@&&&&&&&&BBBGGP5Y??7!!!!!!~G####BPB##########J:::::^^^^~~~~~~!!!!7J??JJY5PGGGBBB###&&&&@@@@    //
//    @@&&@@@@@@@&&&&&####BBGP5YJ?77!!7!!~7#####PB##&&&&&&&B~::^^^^^^^^!~~!!7?7??JJJJY5PPGBBB####&&&&&@@@@    //
//    @&@@@@@@@@@&&&&#&&###BBGP5YYJ???7!!!~5&&&&G#&&&&&&&&&5^^^^^~~~~~~7!~!!!J??JJY5PPGGBB######&&&&&&@@@@    //
//    @@@@@@@@@@@@&&&&&&&&&##BBGP5YJY?7777!!B&&&G#&&&&&&&&&?^^^^^~~~~~~!7!!!!J555PGBB#####&&&&&&&&&&&@@@@@    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MJ is ERC1155Creator {
    constructor() ERC1155Creator("Mid Journal", "MJ") {}
}