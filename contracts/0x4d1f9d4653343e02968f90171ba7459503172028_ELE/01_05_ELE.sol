// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ELEPHANTS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBBBBBBBBBBBBBBGBGGGGBGGBGGGGGG    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBGGGGGBBBBGGGGGGBBBBBBBGGGGGGGGGGGGGGGGGGGGGGBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGG    //
//    BBBBBBBBBBBBBBBBBBBBBBBGGGGGGBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGG    //
//    BBBBBBBBBBBBBBBBBBBBBBBGGGGGBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGG    //
//    BBBBBBBBBBBBBBBBBBBBBBGGGGBBBBBBBBBBBBB#BBGPYJ?777?J5PGGGGGGGGGGGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB##BG5J7~^::::......:~7JPGBBGGGGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB##PJ!^:::::::::::::......:~?YGBBBBBBBBBBBBB################BBBBBBBBB    //
//    BBBBBBBBBBBBB5J77!!!!!!!!77P#B##5!^:^^^^^^^^::::::::::::::...^7PBBBBBBBBG7!!!7777777?JPB######BBBBBB    //
//    BBBBBBBBBBBB!.:::::.:::::::?###P^^^^^^^^^^^^^^::::::::::::::::^J#B##BBBBJ......::::::::7###########B    //
//    BBBBBBBBBB#Y.:::::::::::^^^Y##&B?!!~~^^^^^^^^^^::::::::::~7J5B##BPJ?PBBB5::::::::::::^^:5&##########    //
//    BBBBBBBBBBB~.::::::::^^^^^~B&&&@@&&#BP5J7~^:^^^:::::::!5B&@@&BY7^:..:!PBB~::::::::::::^^~B##########    //
//    BBBBBBBBB#J.::::::^^^^^^^^?#&&#5YJP#@@@@@#P?^^^::::::[email protected]@@#5?~:..::::::^P#J::::::::::::^^:J&#########    //
//    BBBBBBBBB#~.:::::^^^^^^^^~P&&B!::::^!?5B&@@@G~^::::[email protected]&P7:....:::::::::7#G^::::::::::::^:~##########    //
//    BBBBBBBB#G:::::::^^^^^^^^7#&#!:^^^^^^:::!5&@@Y:^::::P#B!...::::::::::::~B#7:::::::::::^^^~B#########    //
//    BBBBBBBB#G:::::::^^^^^^^^J&&Y:^^^^^^^^^^::[email protected]@Y:^^:::PB#7.::::::::^^^^^:!B#Y::::::::::^^^^~G#########    //
//    BBGGGBBB##?::::::^^^^^^^^5&&?:^^^^^^^^^^^:?&@J:^^:::5##?::::::^^^^^^^^:?##G^:::::::^^^^^^Y##########    //
//    GGGGGGBB###Y::::^^^^^^^^^G&&?:^^::^^::::::?&&7:::::^P#&J:::^^^~~^^^^^^^J##B~:::^^^^^^^^^Y&&#########    //
//    GGGGGGBB###&Y::^^^^^^^^^~B&&?:^:!5PP5!::::?&&GJJJJJ5##&Y::^^?PGGP7^^^^^Y&##!:^^^^^^^^^^[email protected]&##########    //
//    GGGGGGBB####&J:^^^^^^^^^~B&&?::[email protected]@&@#^:::J&&@@@@@@&##&5^^^!&@@@@#~^^~^5&##7^^^^^^^^^^[email protected]&&##########    //
//    GGGGGBBBB#####!:^^^^^^^^~B&@Y:^~5&@@&Y::::J&&57777!!P&&G~^^~5&@@#Y~~~~^P&##7^^^^^^^^^7&&&###########    //
//    GGGBBBBBBB###&5:^^^^^^^^^G&@5:^~~!77~:::::J&&7:^^^^^?&&B!^^~~!?7!~~~~~~B&##7^^^^^^^^^[email protected]&############    //
//    BBBBBBBBBB####B^:^^^^^^:^P&&5:^^^^^^^::::^Y&B^^^^^^^!#&&Y^^^~~~~~~~~~^!#&&B!^^^^^^^^!#&#############    //
//    BBBBBBBBBBB####~::^^^^::^5&&5:::^^^^:::::7#&7:^^^^^^^B&&&Y~^^^~~~~~~^^J&#&G!^^^^^^^:7&&#############    //
//    BBBBBBBBBBB####~::::::^^^Y&&#!:::^^^^:::^G&5:^^^^^^^^5&&&&Y~^^^^~~^^!Y#&#&G!^^^^^^^:!###############    //
//    BBBBBB##BBB####~::::::^^^5&&&#PJ7^:::^::5&B^:^^^^^^^^7&&&&#J~^^^^!?P#&&&#&B!^^^^^^::~###############    //
//    BBBB#####BBB###7::::^::^?B#&&&&@&#P?^::?&&?:^^^^^^^^^^B&&&&G~~!JG&@@&&&###&J^:^^::::7###############    //
//    BBB######BBB###G:::::^7P###&&&&&@&&@#5J#&#~^^^^^^^^^^:J&&&&#5B&@BP#@@&&&##&&G?^::::^G&##BBBBB#######    //
//    B########BBB###&7.:~?G##BB##&&@@G7!YB&&#&B^^^^^^^^^^^:!#&#&&@&GJ7!!5&@&&&##&&&BJ~:.!&###BBBBB#######    //
//    #########BBB####57YB###BBB###&BJ^:^^!?P#&#^^^^^^^^^^^^^G&#&#PJ!~~~^~?G&&&&##&&&&#5?Y&##BBBBB########    //
//    #########BBBB####&##BBBBBB##BJ~:::^^^^~7P&!:^^^^^^^^^^^Y&&BJ!~~~~^^^~~JB&&&####&&&&&##BBBBB#########    //
//    #########BBBB#####BBBBBB##BY^:::^^^^^^!?5&7:^^^^^^^^^^^J&&#BPY7~^^~~^^^~JG&&#####&&#####B###########    //
//    #######BBBBBB###BBBBB###GJ^.::^^^^~7YG#&&&7:::^^^^^^^^^J&#&&&&&BPJ7~~^^^:^!YG###########BBBB########    //
//    #######BBBBBBBBBBBBBG5?~:.:^^~!7JPB#&####&7:::::^^^^^^^?&###&&&&&&#BP5Y?7!~^^~?5G#####BBBBBBBBB#####    //
//    #######BBBBBBBBBBBPJ!!!?J5PGB##&&&#######&7:::::^^^^^^^?&&###&&&&&&&&&&&&##BGP5Y5G#BBBBBBBBBBBBBBBBB    //
//    ######BBBBBBBBBBBBBB##&&&&&&@&&&&########&7:::::^^^^^^^Y&&###############&&&&&&&##BBBBBBBBBBBBBBBBBB    //
//    ######BBBBBBBBBBBB#########PYJJJJJ5G#####&7:::::^^^^^^^5&&#######################BBBBBBBBBBBBBBBBBBB    //
//    ######BBBBBBBBBBBBBBBBBBB#Y::::::::~P&##&&!::::^^^^^^^~5&&#################BBBBBBBBBBBBBBBBBBBBBBB##    //
//    ######BBBBBBBBBBBBBBBBBBB#G:::^^^^^:!PB##G^::::^^^^^^^^Y&&#################BBBBBBBBBBBBBBBBBB#######    //
//    ######BBBBBBBBBBBBBBBBBBB##~:^^^^^^^:^~~~^::::^^^^^^^^^J&##################BBBBBBBBBB###############    //
//    #######BBBBBBBBBBBBBBBBB###!:^^^^^^^:::::::::^^^^^^^^^^Y&###########################################    //
//    ########BBBBBBBBBBBBBBB###&G~:^^^^^^^^:^^^^^^^^^^^^^^^!B&###########################################    //
//    ##########BBBBBBBB#########&BY!~^^^^^^^^^^^^^^^^~!7J5G#&############################################    //
//    ############################&&#G5YJ?7!!!!!!77JYPB#&&&&&#############################################    //
//    ###############################&&&&&&######&&&&&&&&&&###############################################    //
//    ####################################################################################################    //
//    ####################################################################################################    //
//    ####################################################################################################    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ELE is ERC721Creator {
    constructor() ERC721Creator("ELEPHANTS", "ELE") {}
}