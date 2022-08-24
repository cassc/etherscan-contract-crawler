// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Unknown Art
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    &&#&&&&&GY!~7!JG&G5Y5PY5#@@@@#GGGGBGB&@@@&&&GBBP5PBB#BG55#@@@&#&@@@@&&@@&@&BBGGGP&&&#&&@&&BP#@@@@&BB    //
//    &&&&&&#PPG!^!7?JBBG5##5Y5#@@#[email protected]@@@#BPGPPPPGB&&#BBP&@@&GB#&#B#&@@&#B&#GPGB&####B##B&BB#&@@@@&    //
//    @@&&&GPB&G~^!7??P&B5GG5J?Y#@&BBBGGG5G&@@&B5PPY5P5GGG&@&&BP5#@@&#GBB#@@&BBGGGGB#@@@@@@@@&&BGB##B#@@@@    //
//    Y#&#PP#&#J~^777??5&P?YGP577P#@@@&@@@@@&#BPGGP5JJYY5GGPGPG#BGG#@&&&@@@&BB#BGB&@@@@@@@@@@@@@#G#&#BB#&&    //
//    YG&BB&#GP?~^7!7?77?5?JBGP5J?7YGB##&BB&G&#GB&G55GB#&&&#BPG#&#PG&B#BB#&BGBB#&@@@@@@@@@@@@@@@@@#&&GGGPP    //
//    P#&&&B5YJ!~^7!7???YPBB##GPY?7???7YBYP&GGBBPG#&@@@@@@@@@@&&B55B&#&B###P5B&@@@@@@@@@@@@@@@@@@@&#&#BGGB    //
//    &&&B5J??!!~^!!PGB&@@@@@@&&#BP??J5YGP#&GYY5#@@@@@@@@@@@@@@@&#GB&BPB&BG5B&@@&@@@@@@@@@@@@@@@@@&B##B#&@    //
//    &#5?!7Y?~!!~!!#@@@@@@@@@@@@@@#5YPG#&&&5JP&@@@@@@@@@@@@@@@@@@&##B#BPPGP#@@#PGPG#&&@@@@@&&@@@@&[email protected]@@    //
//    Y7!~??Y?~~!~!!#@@@@@@@@@@@@@@@&BP55B#BJY&@@@@@@@@@@@@@@@@&&@@&BGGGGG#G&@&57^:^75&@#GPJJB#@@@#[email protected]@&#    //
//    ^[email protected]@@@@@@@@@@@&@@@&[email protected]&&@@&@@@@@@@@&BB##@@@BPPPBGBG&@@#PY7?P#&&G?^:^!5#@@P5B#@@&#    //
//    GPPJJ7~7?Y~^[email protected]&@@@@@@@@@&&@&@@#P??Y5P&@#[email protected]@B&&&@@&#GJ77YYB&@&GGB#BBP#@@@@&B&@@@&@#PJ5PB&@#JPB&@&&B    //
//    &&#BP?!?55~^!!P#G#&@@@@@@&BGBG&@&#57?JJ&@&PG?~~7?G&&G~.::^[email protected]@#B##BBPG&@@@@@@&&&#&&@B&@@@&55&#&&@&P    //
//    #&&GBG7755!^!777!7YB&@&BY7~~!J#&@#[email protected]&57!^~!?B#@&#PYYG#@@@@#[email protected]@@@&#######&@@@@&#G##B#[email protected]@@    //
//    #&&PG#57?Y!^!!!::^!P&@BBY!:^?JP#&[email protected]@@&&#BP#@&&@@@@@@@@@@&BBGBBP55P&@@&BGB###GB&@@@&PP5PGPPB#@@    //
//    #GG5P&#Y7?!^!!G#GB#&&@[email protected]&#G&&&@@GY7GBBGB&@@@@@&@&#G&&&&@@@@@&P5B&&&&GP5P#@&&&&#####&@@&G55GGBP5&&&@    //
//    ~:^!5##Y!7!~!7#@&@@@@@#&@@@@@@@@&P7?P5J?JG#&@@@@&B#GBBB#&@@@##Y5P#@&&&G55B&@@@@&&@@@@&BBGBPGBBP5B&&&    //
//    !~~?P##P77~~!7#@@&@&&##@##@@@@&&GY???GY??YB&#&@&#5PBBBBPB&@&&PJYGB#&#BGP5P&@&@@@@@@&@#GBBPGB#BBPP#@@    //
//    #G#&##[email protected]&#[email protected]@@&&BY7J?Y#[email protected]&@&&#B##GBB&&@@GJJPBGBBBG555P&@&###&@&&@&&#B&@#BBPGGG#&    //
//    ##&&#[email protected]&#GBB##BB&@@&&#P5?JPGBYB#JJJP#@@@@@@&#&@@@&&PJ5PGGBBGGGP5PB#BGPGB&&&@#B###&&#BB&&BPG    //
//    BG#BGGPJ77!^[email protected]&#5GGGGBG&@&@#JY5YYGGP55Y??GGJ5G&@@@@@@&#G5&BPPB#&&&&@@@&##B5PGGG&#B&#GPBPB&&B&&###B    //
//    PGBPGPYY5J!^!!5#@&BBGGGB&@@#PYY?YY5GB#GPY5JJJJYP&GG&B##BGYPBB#&@&@@@@@@@@@@&#BP5G#BG&#GGPG###B#BB###    //
//    B#BGP?7JY?!~!!7?5#@@@&@@@&BJ??5YPGB#&&&&###BG55P5Y5#5BB#P55P&@@@@@@@@@@@@@@@@@&GPBBG&GGG#&&&@@@@@&&&    //
//    #GJYG?^7??!~!!PJ~J&GB#@BY5PJY5PG##@@@@@@@@@@@&BGJYYBPBG5PP5#@&@@@@@@@@@@@@@@@@&&#BBBBPG&@@@@@@@@@@&@    //
//    J?!~~~!7JJ!^!!5J!J#?7JGP7J?7?5B&@@@@@@@@@@@@@@@@BP5GP#BGP5#@&&@@@@@@@@@@@@@@@@@&GPGGG#&@@@@@@@@@@@&#    //
//    ^~7?Y5PB#B!^[email protected]@@@@@@@@@@@@@@@@@@#BGPP#[email protected]@###B##&&@@@@&&@@@&@@GG#B&@@@@@@@@@@@@@#&    //
//    YG#&@@@@@#7^[email protected]&#[email protected]&@@@@@@@@@@@@@@@@@@@&BPPP5G#@@B?^:^!5#@#P?775#&&@@GGB#@@@@@@@@@@@@@@&G    //
//    @@&&@@@@@@?^[email protected]@@@&PJYP?5PP&@#@@@@@@@@@@@@&@@@&@@@#555J5#@@&B5J55B#@#J~:^75#&@#PB#&@@@@@@@@@@@@@@@#    //
//    #GB#@@@@@@Y:[email protected]@@@@#5YJJG#@@@B&@@&@@@@@@@@B&&&#&@@&P55Y5G&@@@@@@@&#@@@#GB&&@@&55G#&@@@@@@@@@@@@@@@&    //
//    B!^~?B&@@@Y:[email protected]@@@@&PY?5PY&@@#&@BPPGB&@@#Y~~7YB&@@&PPB#55B&&@@@@&#[email protected]@&@@@@@&&BY&&BG&@@@@@@@@@@@@@@@    //
//    #5^..Y#&@@J^^[email protected]@@@@&[email protected]@&GJ^::7G#@&B7^[email protected]@@&GPY5YYB&&&@&#BBB####@@@&#&PPB#BG#@@@@@@@@@@@@&#G    //
//    @&G55G#@@@Y^[email protected]@@@@@#[email protected]@&G5YY5G&&&@@&##&@@@@@&GG55PGG#@&&&GPPBPYPG&@@@&BPB##GG#&&@@@@@@@&GY7!7    //
//    @&&&&&&BB&[email protected]@@@@&G5YY5PG&@@@@@&@@@&B&@@@@@@@@@@#BBPPP#BP#@@@&&#####&@@@&#GGB&&#BGB&&@@@@@&&G!^~!    //
//    #&@@@#5^:[email protected]@@@#[email protected]@@@@@@&&BG&&&&&@@@&&#BB#&GGGPYP#@@@@@@@@@@&#BBGPGGPGB#GBBB#&@@@&#5?YG    //
//    @@@@@@B?::[email protected]@&GJ?7JGBBB5Y5##&@@@@#B5555PP&@@&B#GPB#BGPPPPY5###&@@@&&@#GPGGGB#P#&&&#BGGGB#&@@&&@@    //
//    #&@@@&&&G?7^~!Y&GJ???J5PGGBBPYG##&@@&#G#&&&&B#@@&&G5PPBBGPPGGBBGGPPB#&#&@#GGBBBGBPPBB#&####BGBBB&@@@    //
//    &@@@@@@@@&?:!7?J777??JYJYY5PP5YB##@@@&BGGBBPPB&@@&YYY5YY5J555PGGBGPGGGP#@#&&BGGGBBB&&&&&&&&#BBGGGBG#    //
//    @@@@@@@@@#?!!7?JYPGGBBBJ?BG5PG5YPP#@@@&B#&&&&@@&B#5P5Y5PGB#&##GGGPGPGB#&@B##B#&&@@@@@@@@@@@@&&#BBBGB    //
//    GGGGGGPGJ!!7Y#@@@&&&&[email protected]#7#@&BPY?77J#@@@@@@@&&##B&&[email protected]@@@@@@@@@@&#PPG#@&[email protected]@@@@@@@@&&&&&&@@@@@&##&    //
//    J???YGGY~!!J&@BB##&&&[email protected]@[email protected]@@&[email protected]#PGBB#BGPGBGPP#@@@@@@@@@@@@@@@&GPG&#G#@@@@@@@@@@@@@&&&&@@@@@@&&    //
//    [email protected]@G#&&#B#G&@[email protected]@@@@[email protected]#YJY5B##[email protected]@@@@@@@@@@@@@@@&@#GG&##@@@@@@@@@@@@@@@@@#GPP&@@@@    //
//    &&#[email protected]@#&&#&#&#&@[email protected]@@@@#5JJY&BJPP5##BP55G&@@@@@@@@@@@@@@@@&@@#BB#&@@@@@@@@@@@@@@&#[email protected]@@@@    //
//    #@@#BP!!7!!?&@##&B&BB##@[email protected]@@@@@P!!7#BY5PPPGPPGG&@@&&@@@@@@@@@@&@@#&@&B#&&@@@@@@@@@@@@@@@#?~?G&@@@@@    //
//    #@@&B5!!7!!7#@BG&&&&&BG#[email protected]@@@@@577JBBBPPGPGPPPP#@&&B55PB&@@&B5J5G#&@&#BB#&@@@@@@@@@@@@@@&BB&@@@@&@@    //
//    &@@&G7!77!!7#@&G#&#&#GY&P?#&@@@&?Y5GB#&[email protected]&B?^^7Y#@&BJ~^!5B&@#BP5P#&@@&&@@@@&&P??5&@@@@@@&&#    //
//    &@@&[email protected]&B#&&&[email protected][email protected]@@&Y7?G&&&BBBB##G555P&@&&BB#&@@&#&###&@@&#[email protected]@&&&&&@&Y~^:?#@@@&&&&PP    //
//    G&@@P7!!77!7#@&[email protected]&BPP#&@GJ&@@#Y?J5B&&&###&&&BP5PPB&@@@@@@&@@&&@@@@@@###&#BGGB#@@@&#&#?^~Y#&@@@&&&[email protected]    //
//    &@@&Y!!!77!7#@&GPJG&@@@@[email protected]&5!?5B#&@@@@@@@@&&GYJJ5#&@@@@&B#BB#B#@@@&B###BP5PBPB#&@@@@GY#&@@@@@@@@B#&    //
//    @@#BJ!!!77!7#@@[email protected]@@@@@B?BJ!JP&@@@@@@@@@@@@@&B55YP&&&@&B5PGGP5G&@@&#B#&##BG#P5BBB#&@@&@@@@@@@@@@@&&    //
//    @BGP?!7777!?B&[email protected]@&&&@@@#7775#@@@@@@@@@@@@@@@@@&[email protected]@@&&BBBBB#@&@@#PB##BPPP55PG##BG###&&@&&&&@@@@@@    //
//    #G5777777!!?G#&@&#BB#&&@&775&@@@@@@@@@@@@@@@@@@@#PPPG&@@&@@@@@@@@@#BPGB#B##&&&#BBBBBBBGPG#BBBB#&&&&&    //
//    [email protected]@&#B##G#G&&??#@&&@@&@@@@@@@&&@#&@@&BG#GP#@@@@@@@@@&#GGG#&@@@@@@@@@@&###GBGGBGGB#B####&    //
//    [email protected]@#BB#[email protected]@&#GGPB&&@#&#B#&B&@@@BGBP5P&&&&&@@&&BBB#&@@@@@@@@@@@@@@@&&&GG#BB&&&&BGGG    //
//    ????JYY5YJ???P&&#[email protected]@#5!^~!P&&@P!~!JG&@@@BBGP55#BGB&&&B#BB&@@@@@@@@@@@@@@@@@@&#BPB###&&&###&    //
//    J?J5BBBB##5?JJYYYYY5G#[email protected]@@&GPGB&&&@#G5YB&&@@#GBB#&#BGG#&&#BB#&@@&&@@@@@@@@@@@@@@@@&#GB#&#@@@@@@@    //
//    5#&@@@@@@@5^??YBBBP55PGYYJY#&@@@@@@@&#@@@@@@@@&&PPB###&#GB&&@&#&#@@@&&@@@@@@@@@@@@@&@@&BGB##&&@@@@@@    //
//    @@@@@@@@@@[email protected]@&&#GP5YYJ?Y#&@@@@&#BG###&@@@&&BG#BGGBBGGPG#@&#&&@@&#B5YPB&@@&GYYG&&@@&B5G#&@&&@@@@@    //
//    ##&@@@@@@@[email protected]@@@@&#B5YY?7P&#&@&#PPPPPG&&&#&GG##B#&&#&#GG#&###&@&#GY!~?P#@&G?77YG#@@&&GP#&@&&&#BB&    //
//    #&@@@@@@@@Y!77J&@@@@&##P555?JG&#@&&#&&&&B&@&&GG#&@@@@@@@@@&&&BBGB&@@&&&&&&&&@&&&&&@@@&&@GG&@&#GY!~7G    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Unk is ERC1155Creator {
    constructor() ERC1155Creator() {}
}