// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Romeo
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ##################################################BBBGGGGGGGBBGGGBBBGGBBBGBBBBBBBBB##BBBBBBBGBBGGBBB    //
//    #################################################BBGGGGGGBBBBGGBBBBGGBBBBGBBBBBB#BBBBBBBBBBBBBBGGGBB    //
//    ###############################################BBBGGGGGBBBBBBBBBBGGGGGBBGGBBBBBBBBBBBBBBBBBGGGGGGBBB    //
//    ##############################################BGBGGBGGGGBBBBBGGGBBGBBBBBBBBBBBBBGGGBBGGGGBGGGGBBBBB#    //
//    #############################################BGGGGBGGGGGGBBGGGGGGGGGGBBBBBBBBBBGGGGBBGGBBBBBBBBBBBB#    //
//    #############################################GPGGBGGGGGGBBGGGGGPPPPGGBGBBBBBBBBBBBBBBBBBBBBBBBBBBB##    //
//    ############################################BGGGBBGGGPP555YYYYY55PPGGGGGBBBBBBBGGGBBBBBBBBBBBBBBBBB#    //
//    ############################################BGGGBGG5YYYYYYYYYYYYYYYYYY55PGGGBGP5Y55GBBBBBBBBBBBBBBBB    //
//    #############################################BGGG5YYYYYYYYYYYYYYYYYYYYYYYPGBB5YYYY555GBBBBBBBBBBBBBG    //
//    #############################################BGGPYYYYYYYYYYYYYYYYYYYYYYYYYGBPJY5YYYYYPBBGBBGBBBBBGGB    //
//    ##############################################BG5YYYYYYYYYYYYYYYYYYYYYYYYYGB5JY5P5YYYYGBBBBBBBBBBBBB    //
//    ##############################################BBPYYYYYYYYYY5YYYYYYYYYYYYYY5PYJY5GB5YYYPBBBBBBBBBBBBB    //
//    #############################################BGBGYYYYYYY55YYYYYYYYYYYYYYYYYY5YYYY55YYYPBBBBBBB##BBBB    //
//    ##############################################GBBPYYYYY55YYYY5YYYYYYYYYYYYYYYYYYY5YYYYPBBBBB###BBBB#    //
//    ######################################B#######BBBBPYYY5PYYYYPPYYYYYYYYYYYYYYYYYYYYYYYYGBBBBBBBBBBBBB    //
//    #################################BBBBBPB########BBBPYY5YYYPGBYYYYYYYYYYYYYYYYYYYYYYJY5GBBBBBBBBBBBBB    //
//    ##############################BBBBBG#BPB########BB##G5YY5BGP5YYYYYYYYYYYYYYYYYYYYYYY55PPGG5Y5PGBBB##    //
//    ############################BBBBBBBBP5G##############B5Y5555YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJY5PPPGBB#    //
//    ##########################BBBBBBB##BGGB###############PYYYYYYYYYYYYYYYYYYYYYYYYYYYYJYYJJYY5PPGGB#&&&    //
//    ##########################B####&&&&##B################GYYYYYYYYYYYYYYYYYYYYYYYYYYYJJ5YY5PGPPB#&&&&&&    //
//    ############################&&&&&&####################BYYYYYYYYYYYYYYYYYYYYYYYYYYYYYPPP55PB#&&&&&&&&    //
//    ##############################BB##B####################5YYYYYYYYYYYYYYYYYYYYYYYYYYYYYPPPG#&&&&&&&&&&    //
//    #########################BBBB#BPGBBBBBB################G55555YYYYYYYYYYYYYYYYYYYYY555PG##&&&&&&&&&&&    //
//    #######################BBBBBBBBGBBBBBBBBBB###############BBBP555PPPYYYYYYYYYYYYYYY55PB&&&&&&&&&&&&##    //
//    ######################BBBBBBBBBBBBBBBBBBBB###################BBBBP5YYYYYYYYYYYYY555G#&&&&&&&&&&###&&    //
//    #####################BBBBBBBBBBBBBBBBBBBBBB#################BBBBGP5YYYYYYYYYYY5GBGB#&&&&&&&&####&&&&    //
//    #####################BBBBBBBBBBPBBBBBBBBBBBB##############BBBB####BBPYYYYYYY5GB###&&&&&&&&###&&&&&&&    //
//    #####################BBBBBBBBBBJ5BBBBBBBBBB##############BBBB#######BP5YY5PGB#&&&&&&&&&&&&&&&&&&&&&&    //
//    #####################BBBBBBBBBBJJBBBBBBBBB#############BBBB#BBB#######BBBB###&&&&&&&&&&&&&&&&&&&&&&&    //
//    ##################BBBB#BBBBBBBBY?PBBBGPBBB############BBB#####################&&&&&&&&&&&&&&&&&&&&&&    //
//    #################BBBBBBBBBBBBBBPYPBG55GB########################################&&&&&&&&&&&&&&&&&&&&    //
//    ################BBGGB&#BBB##BBBBBBBPPGB########################################&&&&&&&&&&&&&&&&&&&&&    //
//    #################&#&&BP5##B##BBBBBBBBB#####################BBB###############&&&&&&&&&&&&&&&&&&&&&&&    //
//    ###################BPYYP&&####B#####BBBB###################BBB#############&&&&&&&&&##&&&&&&&&&&&&&&    //
//    ################BP5YYY5BGGBBGBBBBBBBBBBG5555G####################BBGB####&&&&&&&&&&&&######&&&&&&&&&    //
//    ################PYYYYP##GGP5PBBBBBBB##BG5YYY5PB########BB#######GPPPPB##&&&&&&&&#&&&##BBBBB#&&&&&&&&    //
//    ################GYYYYP##BG55PBBBBB#BBB#GYYYYYYP#########BBBBB##BPPPPGB#B#&&&&&&#####BBBBBBB#&&&&&&&&    //
//    ################BYYYYYG#B5555#&########5YYYYYY5G#####BBBPPPPPGGGGGB###BB#&&&&&&&&#BBBBBBBBBB&&&&&&&&    //
//    #################5JYYYY555555B&&&#####GYYYYYYYYG#B##BGPPPPPPPPPGB#&&&&&&&&&&&&&&#BBBBBBBBBBB#&&&&&&&    //
//    #################GYJYYYYYYYYYPB#&#BB&BYYYYYY55G####BGPPPPPPPPGB######&&&&&&&&&&&#BBBBBBBBBBBB#&&&&&&    //
//    ##################GYYYYYYYYYYYYYPBB#&GGGPP5PGB####BGPPPPPPPPB###&########&&&&&&&&#BBBBBBBBBB#B#&&&&&    //
//    #####BBGGB##########G5YYYYYYYYYY5B5555PPG5Y5#######GGGGGGGGG#&&&&&&&&&&&###&&&&&&&BBBBBBBBBBB###&&&&    //
//    ###BPPPPPPG##&#&&&&&#BPYYYYYYYYYPGYYYYYY5YYYP#&#####BGGGGGGB&&&&&&&&&&&&&&&##&&&&&#B##BBBG55PGBB#&&&    //
//    ###BPPPPPPPGB#B#&&&&&&#B5YYYYYYYY5YYYYYYYYYYYB#######BBBBBB#&&&&&&&&&&&&&&&&&&#&&&&BBGPPGP5G5PG###&&    //
//    BGBBBGGBGPPPB##&&&&&&&&&#G5YYYYYYYYYYYYYYYYYYG&###&&&&&&##B&&&&&&&&&&&&&&&&&&&&#&&&BPPGPPB########&&    //
//    #######&##B##&&&&&&&&&&&&&#BG5YYYYYYYYYYYYYY5#&&#&&&&&&####&#&&&&&&&&&&&&&&&&&&&&#&#BGBBB###B#####&&    //
//    #&&&&#&&&&&&&&&&&&&&&&&&&&&&&#GYYYYYYYYYYYY55B&&###&###BBB#&#&&&&&&&&&&&&&&&&&&&&&#&#B######BBB##B&&    //
//    BBBBB#&&&&&&&&&&&#&&&&&&&&&&&&#GYYYYYYYYYYYYYP#&&&####BB###&#&&&&&&&&&&&&&&&&&&&&&&#&####BBB######&&    //
//    GGGGGGBBB&&&&&&&&&&&&&&&&&&&&&&&G5YYYYYYYYY555P######BBB#&#&#&&&&&&&&&&&&&&&&&&&&&&&&&####&&&&&&&&&&    //
//    GGGGGPPPGB&&&&&&&BBGG#&&&&&&&&&&&B5YYYYYYYYY555PGBGBBBBB##&&#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    GGGGGGGGGGBB###&#GPPG#&&&&&&&&&&&&#P5YYYYYYYY555PPGBBBBB&#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ROMEO is ERC721Creator {
    constructor() ERC721Creator("Romeo", "ROMEO") {}
}