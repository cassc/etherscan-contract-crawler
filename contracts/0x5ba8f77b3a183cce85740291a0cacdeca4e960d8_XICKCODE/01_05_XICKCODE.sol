// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Xick Code
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                             //
//                                                                                             //
//    BBBBBBBBBGBGGGGGGGGGGGGGGGGGGGPPPPPPPPPPPPPPPPP555555555PPPPPPPPPPPPPGGGGGGGGGGBBGGBB    //
//    GGGGGGGGGGBGPPPPPPPPPPPPPPPP5555555555YYJ?7?JJYYYYYYJYYYYYYYYY5555555PPPPPPPGGGGGGGGB    //
//    BBGGGGGGGGGGGGPPPPPPPPPPPPP55YYYYYYYJ?7!7777?77?JY5YYYYYY55Y555555PPPPPPPPPGBBBGGBGGB    //
//    BBBGGGGGGGGGGGGGPPPPPPPP555YYYYYJ?7!!!7??7!!7??7!!?JYYYYYYYY5555555PPPPPPPPGGGGGGGGGG    //
//    BBBBBBGGGGGGGGGGPPPPPPP55555YJ?7777!JJJJ??77?JJYYJJJ??JYYYYY5555PPPPPPPPPPPPGGGGGGGGG    //
//    BBBBBBBGBGGGGGGGGPPPPP5555YJ?7??JJJJYYYYJJJJYYYYY555JJ??JYY555PPPPPPPPPPPPGGGBBBGGGGG    //
//    BBBBBBBBBBBGGGGGGGGGPPP55Y??JY55YJJJY?JJ?77?JY55Y55555YYJ?J55P5PPPPPPPGPPGGGGGGGGGGGG    //
//    BBBBBBBBBBBGGGGGGGGGGGPYJ?JYYY555Y555555J?7?JY55PP5555YYYYJJY5PPPPPPPPGGGGGGGGGGGGGGG    //
//    BBBBBBBBBBGGGGGGGGGGPYJJJY55555Y5PPP555555YY55PPPPPPPP5555YYJJY5PPGGGGGGGGGGBBBBBGGGG    //
//    BBBBB##BBBBBGGGGBGP5YYY555PP555PGPP5Y55YYYYYJY5PPPGGGPPPPPPP555555PGGGGGGGBBBBBBGGGGG    //
//    BBBBB###BBBBBBBB5555PY5PGGGPPP5P555J??JY5GB##PJJY5PPPGGGGGGGGPYY5PPPGBBBBBBBBBBBBBBBB    //
//    BBBB#####BBBBBBPGGPP55PGGGGGBBGPPGGBGB&@@@@@@@@&###BPPGBBBBGGPPGGGBBGBBBBBBBBBBBGGBBB    //
//    BB##########BBGB#BBGPGGBBGGBBGB&&&@@@@@@@@@@@@@@@&&@#GGBBBBBBGGGGBB#BBBBBBBBG55PGBBBB    //
//    BB#BB########BB##BBBGBBBPGBBGG#####&&&@@@@@@@@@&#BB##BBGBBGGGBBBBBB#&BBBBBBBGPBBBBBBB    //
//    BBB##########B#&#BBBGBBBBBBGGBBBBBB##&@@@@@@@@@&###BBBBBB#BGBBBBB#BB##BBBBBBBBBBBGGGG    //
//    BB#########BBB&&##BBBBBBBBBBBBBBBBB&@@@@@@@@@@@@@&BBBBBBBGB#BBBBB####&BBBBBBBBBBGGGGG    //
//    B####BBBBBBBB#&##BBPGBBB#BGBBBBGG#&@&&&&&@@@&&&@@@&BGBBBBBB#BBBBBBB##&#BBBBBBBBBBBBGG    //
//    ###BBBBBBBBBB#&###BPG##BBPPGGGPG#&&&&&&&&&&&&&&&&&&&B5GGGBBB####BB###&&BBBBBBBBBBBBBB    //
//    ###BBBBBBBBBB#&###BGG##BGGGGGGB&&&#BP55PGB#BG55PB#&&&#BGBBBB###GGBBB##&BBBBBBBBBBBBBB    //
//    ##BBBBBBBBBBB&&###BB####BBBBB&@@@@@@&#PYPB&G55B&@@@@@@&#BBBBB#####B###&#BBBBBBBBBBBBB    //
//    BBBBBBBBBBBB#&##BBB#&&#BBB#&@@@@@@@@@@&&&##&&&@@@@@@@@@@&#BBB##&&#####&&BBBBBBBBBBBGB    //
//    #BBBBBBBBBBG#&#####&&&###&@@@@@@@@@@@@@&#5?P&@@@@@@@@@@@@@&&###&&&#####&BGGGBBBBGGPPB    //
//    ####BBBBBBBB&#####&&&##&@&@@@@@@@@@@@@&#B7^5B&@@@@@@@@@@@@@@@&#&&&&####&#GBGBGGGGGGBB    //
//    ##BBBBBBBBG#&##BB&#&&#&&&@&&&&@@@@@&##BB5JYYPBBB&&&@@@@&&&&@&&&&@&&&####&GGGGGGGGBBBB    //
//    #BBBBBBBBBG&#B#B&&&&&#&&@&&#[email protected]@&P5PGP5Y5PGGGB#&@@&&&@@&&&B##&#GBGBBBBBGGG    //
//    ##BBBBBBBBB&##B&@&&@@&#&@&##[email protected]@@@@GPPGB#BBB#B###&@&#&@@&&@&B##&GBBBBBBBGGG    //
//    ##B#BBBBBG#&#B&&&&&@@@&&@&&#&&&&&&#[email protected]@@@@@&BPB##&&&&&&#&&@&&@@@&&&@#B#&BBBBBBBBBBB    //
//    ###BBBBBBG&#B#&&&&&@@@&@@@@@@@@&&&#[email protected]@@@@@@BGBB&&&@@@@@@@@@&&@@&&&&&#B##GBBBBBBBBB    //
//    #BBBBBBBBB&#B&&&&&&&&&@@@@@@@@@@@@&#GGG&@&#&@&GGG#&@@@@@@@@@@@@&&@&&&&&&B#&BBBBBBBBBB    //
//    BBBBBBBBG##B#&&&&&&&&@@@@@@@@@@@@@&#GGPGP#GBPGPGG#&@@@@@@@@@@@@@&&&&&&&&#B#BGBBBBBBBG    //
//    BBGGBBBBG##B&&&#&&&&@@@@@@@@@@&&@@&#GPGPP5PGPGGGG#&@@&@@@@@@@@@@@&&&&#&&&B##GGGGGBBBG    //
//    5BBBBBBGB#B#&&###&&&@@@@@@@@@@&&&&&#BGGPG5GGGPBG##&&&&@@@@@@@@@@@&&&###&&###BGGBBBBB#    //
//    JYPGPGBG#&#&&#####&@@@@@@@@@@@&&&###BGB5BGGBPGBB###&&&@@@@@@@@@@@@&#####@&#&#GGBBBBBB    //
//    GPYY5GP5#&#@&#####&@@@@@@@@@@@@&##BB&GBPBGPBP#B&####&@@@@@@@@@@@@@&#####&&#&#GGGBBGGB    //
//    GBG5JJJG#&&&&####&@@&@@@@@@@@@@@&##B#GG5#@&&#&#&###&@@@@@@@@@@@@&@@&####&&&&#55GPYGBG    //
//    P55G5Y5P#&&&@&###@@&&@@@@@@@@@@@@@&B#GG5#@@@@&B##&#@@@@@@@@&&@@@&&@@###&@&&&#PPPJ!J57    //
//    PBB5P#GPB&&&@&###@&&@@&&&&@@@@@@@@@&&BB#&@@@@&B&@&#@@@@@@&&&&&&@@&@@##&@@&&&#BB#G5J5J    //
//    BBYYYBBBB&&&&@@&#&@@@&&&&&@@@@@@@@@@@#[email protected]@@@@&#@@&#@@@@@@&&&&&&&@@@&#&@@&&&&##B&#P5PP    //
//    J?YGG##B##&&&@@@&#&@&&&&&&&@@@@@@@@@@@[email protected]@@@@@&@@&&@@@@@@@&&&&&&&@&#&@@&&&&##B#&BPPBG    //
//    B#BGGB&##&&&&&@@@&&#&&&&&&&&@@@@@@@@@@[email protected]@@@@@@@@&&@@@@@@&&&&&&&&#&@@@&&&&&&##&#GGB#B    //
//    5GBBGGB&&#&&&&&@@@@&&&&&&##&&@@@@@@@@@[email protected]@@@@@@@@&@@@@@&&&&&&&&&&&@&&&&&&&&#&&#GGB##G    //
//    GPGGB###&&&&&&&&@&&&&&&&&&##&&@@@@@@@@&B&@@&@&@@@&@@@@&&&&#&&&&&&&&&&&&&&&#&&#GGB##GG    //
//    ##BBBB#&#&&&&&&&&&&&&&&&&####&&@@@@@@&&B&&&&&@@&&@@@@&&&####&&&&&&&&&&&&&&&&##BBB#BBB    //
//    GGBBBBBB##&&&&&&&&&&&&&&&&&####&@@@&&@&#&&&&&@@&@@@@&&&##&&&&&&&&&&&&&&&&&###B#B###B#    //
//    PPPPGGGB####&&&&&&&&&&&&&&&&&##&&&&&&@&#&&&&&&&&&&&&&###&&&&&&&&&&&&&&&&##&&BBBBBBB#&    //
//                                                                                             //
//                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////


contract XICKCODE is ERC1155Creator {
    constructor() ERC1155Creator("Xick Code", "XICKCODE") {}
}