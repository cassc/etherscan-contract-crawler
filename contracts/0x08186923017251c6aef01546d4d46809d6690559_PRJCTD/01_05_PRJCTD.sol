// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Projected Dreams
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                             //
//                                                                                             //
//                                                                                             //
//    Result                                                                                   //
//    @&&&&&&&&&&####&&&&&&&&&&&#####################&&&###########&&&##############&&&&&&&    //
//    &&&&&&&&#######BG5YJ???77!7!!!!7!~!!!!!!!!77!7777777777777???JJY5PGB############&&&&&    //
//    &&&&&&&######BY~^^^^^^^^~^^::^~~^^:~~~~^~~~~~~~^~~~~~~~~~~~~^^^^^~~~!5###BB######&&&&    //
//    &&&&&########B!^^^^^^~^~~~^^^~~~^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^:^PBBBB########&&    //
//    &&&&####BB##BG!^^^~^^~~~~~~^^~~^^^^~~~~~~~~~~~~~~~~~~~~~~^^^~~~~^^^^^^5BGGGB#B#####&&    //
//    &&&&####BBBBGP~^~^^:^~!!~~~^^~^^^~~~~~~~~~~~~~~~~~~~~~~~~^^~~~~^^^^^^^YGGGGB#B#####&&    //
//    &&&&####BBBBGP!^~^::::^~~~~^^^^^^~~~~~~~~~~~~~~~~~~~~~~~~~^~~~~~~^::::YGGGPB#B#####&&    //
//    &&&&####GGGBBP~^~^^^^^^^:^~~^^~~~~!~!!~~~^^^~~~~~~~~~~~~~^^^~~~~~^:^^^YGGGPBBB#####&&    //
//    &&&&####BGGGGP!^^~~~~~^^::~~~~~~~~~~~~~~~^^^^^^~~~~~~~~~~^^^~~~~~^^^^^YGGGPGBB#####&&    //
//    &&&&####BGGGGP!^^^~~~~^^^:~~~~~~~~~~~~~~^^^^^^^~~~~~~~~^~^^~~~^^^^^^^^JPGGPGBB#####&&    //
//    &&&&####BGGGGP!^^^^~^^~~^^^~~~^^^^~~~~~~^^~~~~^^^^^^~~~~~~^~~^^^^~^^^^JPGGGG#B#####&&    //
//    &&######BBBGGP!~~~~~^^^^^^^~^^^^:::^~~~^^^^^~~~~~~^^^!~~~^^^~^^^^^^^^^YPPGGG#B######&    //
//    #&#&####BBBGGP!~~~~~^^^^^^^^^^^^^^^^^^:^J5Y!^^^~~~^^^~^^^^^~^^^^^^^^^^YGPGGGB#######&    //
//    #&#&####BBBGGP!^^~~^^^~^^^^^^^^^^^^^^::~#@#?^^^~~~^~^^^^^~~~^^^^^^^^^^YGGGGB########&    //
//    &&&&##&#BBBBGP!^^::~~^^^:^^^^^^^^^^^^::J#&BJ:^^~~~^~~~~^^::^^^~^^^^^^:YGGBBB######&#&    //
//    ##&&#&##BBBBGP!^^^:^^^^^:^^^^^^^^^~~^!JB#BG5J~^~~~~~~~~~^:.:^~~^^^^:^^YGBBBB######&&&    //
//    ##&&#&&&#BBBGP!~^~~~^:^^::^~^~~~~~~~~G&#####GY~~~!~~~~~~~^:..:^:^^::^^YBBBBB######&&&    //
//    &#&&#&&&#B#BBGJ!^^~^^^:::.:^:^^^^^^^?#&&####GP?~~~~~~~~~^^:::.:::^~7J5GBBB######&&&&&    //
//    &&&&#&&&#######BGP55YYYYJJJJJJJ?JJJ?G&B#####GPG??JJJJJJJJJJJYY55PGBB###BB#######&&&&&    //
//    &&&&&&&&##########&#########BBBBBBBB&#B##BBBBPGYBBBBBBBBBBBB##BB###BB##B########&&&&&    //
//    &&&&&&&&###########BB#BBBBBBBBBBBBBGG5B##BPBG5JYGGGGGGGGGGBBBBBBB#BB###B#&######&&&&&    //
//    &&&&&&&&&##########BB#BBBBBBBBBBBBGP5YB##B5BG5!PPPPGPGGGGGBBBBBB##BB###B#&&####&&&&&&    //
//    &&&&&&&&###########BB##BBBBBBBBBGGPYJ?BB#G5BB5^YGPPGGGGGBGBBBBBB##BB###B#&&#####&&&&&    //
//    &&&&&&&&####&######B###&##BBBGGPJ??7!~BBBPYBBJ^!7777JPGGGGBBBBBB##BB###B##&#####&&&&&    //
//    &&&&&&&&&#############BBGPP555J77!!7775&#Y?#B7~~~~!!!7JPGGBBBBB#BB#B######&&###&&&&&&    //
//    &&&&&&&&&##&#####BGPP5YYYJJJJ7!!!7!77!7#&J?&#!!!!!!!!!!?PGGBBBB###B#######&&###&&&&&&    //
//    &&&&&&&&&###BGGP55YYYYYYYYJ7!!!!!!!!!~~YB~~B7^~~~~~~~~~~~75GGGBB###&&#B########&&&&&&    //
//    &&&&&&&#BGGPPP5YYYYYYYYYYYYJJJJ????????5#??B577777??????77JPB######&&&#########&&&&&&    //
//    &&&##BGGGPPPPP55555555YY?!!!!!!!!!!!!!!77!7?J!!!!~~~~~~~~~~~?5PPPPPPPPPPB####&#&&&&&&    //
//    ##BBGGGGGPPPPPPPPPP5555YYYJJJJJJJJJJYYJJJJJJJJJJJJ??JJJJJJJJJJ55555PPPPPGGBB##&&&&#&&    //
//    BBBGGGGGGGGPPGGPPPPP55YYYYYYYYYYYYYYYYYYYYJYYYYYJJJJYYYYYYYYYYJY5PPPPPPPPPGGG##&&&###    //
//    BBBBBBBBGGGGGGGGGGPY????777???7777?7777777!7777777!!!!!!!!!!!!77?YPPPPPPPPPPGGGB#####    //
//    BBBBBBBBBBBBGGGGGG5YYYYYYYYYYYYYYYYYYJJJJ???????777!77777777777777J5PPPPPPPPGGGGGGBBB    //
//    BBBBBBBBBBBBGGGGP55PPPPPPPPPPPPP55555555YYYYYYYJJJJ?????????????????Y5PPPPGGGGGGGGBBB    //
//    BBB#BBBBBBBBBGP55555555555555555YYYYYYYYJJJJJJJJJJJJJJJJJJJJJ????????JY5PPPGGGGGGGGGB    //
//    BBB#BBBBBBBBBP5P55555Y555Y5YYYY5YYYYYYYYJJJJJJJJJJJJJJJJJJJJJJJJJJJJYYYYY5PGGGGGGGBBB    //
//    BBBBBBBBBBBBGGPPPPPPPP5555555555YYY55YYYJYYYYYJJJYJJJJJJJJYYJYYYYJYYYYYYYY5PPGGGGGGBB    //
//    ###BBBBBBBBGGGGGGGGGGPPPPPPPPP5555555555Y5555YYYYYYYYYYYYYYYYYYYYYYY5555555PPGGGGGGGB    //
//    ########BBBBBBGGGGGGGGGGGGGGGGPPP5PPPPPP5555P55555555555555Y5555555555PPPPPPPPGGGBBBB    //
//    ########BBBBBBBBGGGGGGGGGGGGGGGPP55PPPPPPPP5PPPPP555Y55555555YY5555555PPPPPPGGGGGBBBB    //
//                                                                                             //
//                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////


contract PRJCTD is ERC721Creator {
    constructor() ERC721Creator("Projected Dreams", "PRJCTD") {}
}