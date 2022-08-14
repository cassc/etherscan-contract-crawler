// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: jubbish
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                                                                                                 //
//                                                                                                                                 //
//                                                                                                                                 //
//                                                                                                                                 //
//                                                                                                                                 //
//                                                                                                                                 //
//                                                           !                                                                     //
//                                                          JP                                                                     //
//                                                          JB~                                                                    //
//                                                          .GG.                                                                   //
//                                                           !#J                                ::                                 //
//                                                            PB~                               .G7                                //
//    :                                                       !GP.                              7#Y                                //
//    ^:....                                                  .Y5?                             JBJ                                 //
//    ~~~~:.......                                             ~JJ.                          :5B?                                  //
//    ~~~~^^^^:...                   .::::::...                .??^                         !P5!                                   //
//    !!~~~~~~~~^^:...        ..:::^^^^^^^^^~~~~^:.:::. .......^YJ7.                      :J5?.                                    //
//    ~!~~!!!~~~!!!!~~~^:::.::^~~~~~^^~~~^^^~~~~~~~~~~~~~~~~^^^^55?~                    .!YY!                                      //
//    ~777!!!!!~!!!77!!~!!~!!!!~~^^^^^~^^^^!!!!!~~^~!!~~~^^~~~!^YY?!:                 .!J55~                                       //
//    !!!7?7!77!77777?J7!7!7J7~~~^^^^^^^^^~?JY555Y?!!~^~~~~~~~^~YY?!^.              .~JY5?:                                        //
//    7!77!77?7!!777777??57Y?~~~~^:::^^^^~~!!7?JP#&#BPJ~~!?7!7!755Y?7^:.          .~JJ5Y^                                          //
//    !77?J???Y7!7!77???JJ?J~^^^^^^^^^^^~~~!!!7Y!?G&&&#GJ7!!!!~?GGPYY!::.       .~?JY5!                                            //
//    !!!??7J?Y57!7777?JJYJ7~~~^^^~~~~~~!~~~!7?PY~55B&&#GGPY?~:JBBBGPY~:::.    :7JY5Y:                                             //
//    ~!7!77?7?J5Y!77??Y5YY!!!~~!!77????7?7!~!7JJ7P?YG#&BGBG5!5####BBBBJ77?!^^!?Y5PJ.                                              //
//    ~~~!!!7???7YJ!!7?YPGY7~~~~!7?YYYY5YYYYJ?7!7?YYPPGB#GBP?75#&&&#BGPP5PGBP5PPP5~                                                //
//    ~~~~~~~!JY??JJ???J5P?7!~~~7JPG5Y5YYPPYGBBGYJJ5BB##G5?~^~?PGGG5J??PPY75B####J::::..                                           //
//    !~~~!!!~!JYJJ?JYJJYY5JJJ?JGB##G5PJ?J5BGGB&#PY5BBB#J~^~~~!JY5PP5YY5YJ7?5B#BY555YYY5555Y?~:.                                   //
//    7!~~~!!!!7JJ5P?P5YYJJYGBBP###B#5PG???P#BGGPP5PPPBBGP5?7!!?YPPP5JJ?JJ5P5YJ7!PBGGBB#BBGP555Y?!:.                               //
//    77!~!!!!!77J5GJJPG555PBBBB##B##GYB5?JJG&#[email protected]@@BYJ?JYPPPP5JYY555J7!!~!~^^^^::.       .::.                              //
//    J7?!~!!!!77?JPGY55G5Y5GBBBB#B&#BYGB7PYG##G55YJ5BGY#&@B55PPGGGPP5PP55YJ?777!:                                                 //
//    7J7?!77!!!77?J55YP5G555B####B###5B#JYGG##BPGBBB##5Y555Y55PGP5YYJ5Y5555J?J55!                                                 //
//    ????77777!!7?JYPG5YY5P5PB&&#BB##GB&P5###BGPB#BB#PYYYYJYP5GP5PYJJJJYYPPY7B&P.                                                 //
//    77J??777?7!!7?J5BP55Y5P5PB###########&&##GPB#B#BYY??J7?J5P5PPPP5YYY5YYJJGJ                                                   //
//    ??Y??7????777?JJ5GG555GGGB##&#&##&#&&&&&#BBB###PYJ?77??YYPPP5PGGP555YYJ!.                                                    //
//    7?JJ?J?J?J????YJYY5PGGBGBB##&&&####&&&&####&&&BPYJ77??JYY5PP55PGPPPY?7^                                                      //
//    !77???JYJ?JJJYY5G5Y5PGGGBB####&######&&###&&&&G55J???JYJYYPP55YY5GP??!                                                       //
//    7777??JYYYJ?J5YPGG555BBGGBB####&##&&#&&#&&&&&#5YJJJ??YJJY5P5YYYJJ5Y??.                                                       //
//    ?777JYJYYYJJJJPGGGP5PGGPPGBB###&&##&###BB#&##BPYJ?J??JJ?JPPJJYJJJ??7~                                                        //
//    J?J?JJJJJJYJYYYPGGPGBP5555PGBBBB&&&##&#BBBBBGGGGGPP5J?7?Y5YJJYJYJ7?!                                                         //
//    55JJJJJJJJ?JJ55PBBGPGG555YPGBBBBB&&####BBGGY7YGBBBP5GYJ??YJ??JJ??!!.                                                         //
//    5YYYYJJJYJJJJPGGPGGGBPGPGPPBBBG#B##&#B#GP5YJ^:YGGGP5Y??JJY??7????~.                                                          //
//    PYPYY55YJJYYYPB#BPPGGPGG5P5PBGBGBBBBBPPY?~    JP55P55??YY?7?????7.                                                           //
//    5Y5PP5555YYYJY5BBPGGPP5PPP55GGGGGGPP5Y?7:     ?P5YYJJ??YY?77?J??7                                                            //
//    PP5PPPP55YYYJYY55P5GGGGPPG5Y5PBGGP55Y?~^:     ^YY???JJJY5YJ?7??J7                                                            //
//    GGGGGGP5Y555Y55BGGP5PGBP5BG55PPBGP5J??!^:     :?YJ5&&###&#BGGG5Y7                                                            //
//    YPGBGGGPPY5YY5PGGBGGP5PGYPG55PPPBPYJ!^:..     ~55JY#@@@@@&&&&&&BY:                                                           //
//    J5BBBGGP55P55P5GGGBGGPYBPPBBPY5GP5?7~.~^.     ~BPJYPB&@@@@@@@@@@B^                                                           //
//    YPBBGBGPPPPPP5PPBGGGGP5BBP5GBGYP5J7!!!!^      :5#G55PB&&@@@&&&#5.                                                            //
//    PPGBBBGGGGP5555PP55GGB5PPG5PPPYY5?~^::.       .~G#&&&###&&##B5?..                                                            //
//    PPPGGGGB#BGP5YY55PPGGP55P555555JJ?~:..:.       .!PB&&&&&&#P5J!.                                                              //
//    GGGGGGB##&B5PPYY5Y5PGPPPG5555YJ7!!~...^.         :~7?YYJ7~.                                                                  //
//    PGGGBGB#B&&B5P5Y555PGP55555YJJ?~..:.                ...                                                                      //
//    PPGGBGPGP#&&BGPYYY555555YYYJ777!~.                                                                                           //
//    GGG#BGGPGB##GPPPPPPP5YYYYJ?7!:::...                                                                                          //
//    GGBBG##PPBBBGYPP55GP55YJJJ!^:.                                                                                               //
//    GBBGPBBP5GBGG5Y5PGG5YYYYJ?!....                                                                                              //
//    GB##PPPG55GPPYYYGG5YJJJJ?7~. .                                                                                               //
//                                                                                                                                 //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JAY is ERC721Creator {
    constructor() ERC721Creator("jubbish", "JAY") {}
}