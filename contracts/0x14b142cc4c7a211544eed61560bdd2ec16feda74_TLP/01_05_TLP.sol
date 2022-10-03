// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Last Pyramid
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ##################################################################################BBBBBBBBBBBBBBBBBB    //
//    ######################################################################BBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    #####B######################################B###############BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBG    //
//    ####B#######################################BBBBBGPBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGG    //
//    BBBBBB#BBB###BBBB####B##########BBBBBBBBBBBBBBBBY!^!YGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGG    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB5?7?!^^75GBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGG    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBPYJY55J77!~?PBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGGPPPPP    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBG555PPPPJ????77JPBBGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPPPPPPPPPP    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGP5PPPP5YJ7!77?????YPGGGGGGGGGGGGGGGGGGGGGPPPPPPPPPPPPPPPPPP    //
//    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPP5YJJJJY?7!~!!77???YPGGGGGGGGGGGGPPPPPPPPPPPPPPPPPPPP55555    //
//    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPP5YJJJY5PGGG5JJJ?7!!!!77?JPGGPPPPPPPPPPPPPPPPPPPPPP55555555555    //
//    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGP5YJJJY5PGBBBBBG5YYYYYJJ?7!!!!7J5PPPPPPPPPPPPPPP555555555555555555    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5JJJY5PGBBBBBBGP55J??JJYYYYYYJ?7!~!7YPPPPPPP5555555555555555555YYYYY    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPP5YJJ5PGGBBBBGGP5Y55PG5YJ?????JJYYYYJJ?7!7Y5555555555555555YYYYYYYYYYYYY    //
//    PP55555555P55555555555555555P5PGGGGGGGP5YY5PGB####GPPP5YJ?777??JJYYYJ??J55555555YYYYYYYYYYYYYYYYYYYJ    //
//    55555555555555555555555555PPGGGGGPP5YY5PGB########BGGGGGPP5YJ?7777??JJJJJYYYYYYYYYYYYYYYYYYYYJJJJJJJ    //
//    555555555555555555555Y555PPPPP5YYY5PGB##########BBPPGGGGGGGPPP5YJ?7!!77??JJJYYYYYYYYJJJJJJJJJJJJJJJJ    //
//    YYYYYYYYYYYYYYYYYYYYYY5P55YYYY5GBB#########BBGGGGBP5YY55PPGGPPPP555YJ?7!!!77?JJJJJJJJJJJJJJJJJJJJ???    //
//    YYYYYYYYYYYYYYYYYYYYYYJJYYPGBBBBBB###BBGGPPGBB##&&BGPP5YYJJJYY5555555YYYJ?7!!!!7?JJJJJJJ????????????    //
//    JJJJJJJJJJJJJJJJJJ?JJ5PGGBBBBBBBBGPP55PPGB##&&&&&&BGGGGGPP5YJ?777?JJYYYYYYYJJ?7!!!7?????????????????    //
//    JJJJJJJJJJJJJJ?JY5PPGGGGBBGGP55YYY5GBB######&&&&&#GPPGGGGGGPP55YJ?7!!!7?JJJJJJJJ??77??????7777777777    //
//    ??????????????YPPGGGGGP55YJJY5PGB############BBGPPJJJYY55PPPPPPPP55YJ?7!!!!!7???JJJ????7777777777777    //
//    ????????????J5PP55YYJJJY5PGBBB########BBGP5YJ???JJ?77!!!77?JJYY555PP555YYJ?7!!~~!!7?????777777777!!!    //
//    7777777777?JYJJ??JY5PGGBBBBBBBBBBGGP5J?7777JY5GBBBGP55YJ?7!!~~!!7??JYY555555YYJ?7!~~~~!!777!!!!!!!!!    //
//    7777777777??JJY5PGGBBBBBBBGGP5YJ?7777?Y5PGB########BBBGGPPP5YJ?7!~~~~!!7??JJYYYYYYJJ?7!~~~~~~!!!!!!!    //
//    7777!!7?JY5PPGGGGGGGGPP5YJ?777?JY5PGBB################B#GGGGGPPP55YJJ?7!!~~~!!77?JJJJJJJ??7!~~!~~~~~    //
//    !!!!7J55PPPPPPP55YJ??77?JY5PGBB############&&&&##BG#####BBGGGGGGGGGGPPPP5YJ?7!~~~~~~!77????????7!~~~    //
//    !!7JYYYYYYJJ?????JJYPPGBB#######################&GJ5GBBBBBBBBBBBBBBGGGGGPPPPPP5YJ?7!~~^^^~~!!7777!~~    //
//    !7???7777??JY5PGGBBBBBBBBB#############&&&#######GJJJ5G#BB#####BBBGGGGGGGGPPPGGGPP555YJ?7!~~^^^^^~~~    //
//    !77??JY5PPGGGGBBBBBBBBB#########################&PYYJ?JPB#######BBBBBBBBBBBGPPPPPPP55555YYJJ?77!~^^:    //
//    YY55PPPGGGGBBBBBB###################&&###########G55YYJJJPB#############BBGGGGGPPPPP555555YYJJJJJ??7    //
//    PPGGGGGBBBB######################&&&&&&&###&&####P5555YYYJJPB#############BBBBBGGGGPPP5GBGGGGPP5YYYY    //
//    BB#######BBBB###############&&&&&&&&&&###&#######PP5555555YYYGBBBBBB#######BBBBBBGGGGGGBBBBBBBBBGP55    //
//    ####&&###BBBBBB####&#####&&&&&&&&&&&&&&&&&&&&&&&#BGGPPPPPPPPPPPGBBBBBBBBBBBBBBBBBBBBBB##BBBBBBBBBBBG    //
//    ###################################&&&&&&&&&&&&&&#BBBBBBBBBBBBBGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    ############################################################################BBBBBBBBBBBBBBBBBBBBBBBB    //
//    ################################################################################################BBBB    //
//    ####################################################################################################    //
//    ####################################################################################################    //
//    &&&&&&&&&&##########################################################################################    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&###&&&&&&#&##########################################    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&########################    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#############    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TLP is ERC721Creator {
    constructor() ERC721Creator("The Last Pyramid", "TLP") {}
}