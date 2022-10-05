// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THE COMPLETELY_FLAWED COLLECTION
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//    ^^^^^^^Just like glass^^^^^^^^^^^~^^^^^^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ^^^^^^^We too^^^^^^^^^^^^^^^^^^^^^^^^^~~^~^^^^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ^^^^^^^Break^^^^^^^^^^^^^^^^^^^^^^^^^^~~^~~!77??????JJYYJ??7!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ^^^^^^^Shattered, from life's sharp edges!JYYYYYJJJJYY555YYJYJ?!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ^^^^^^^Shards harden my hands^^^^^^^^^~?JY5555JYYY55YYYYJJJJJ!^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ^^^^^^^With pieces^^^^^^^^^^^^^^^^^^^^^~7JY5YYY55JYG5JJ???JYY?~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ^^^^^^^Glimmering like Gold^^^^^^^^^^^^^!YJYYJJYY?YG5?7?Y555Y!^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ^^^^^^^So when I tell you^^^^^^^^^^^^^~^~?J?JJ5PGG!!5JYY5555J~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ^^^^^^^The heavens^^^^^^^^^^^^^^^~^^~~^^^7YY555Y5PPJYJJY5P55?^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ^^^^^^^Have poured her magic^^^^~^^^~~~^^~JYYYYJJJYYJJJJY5557^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ^^^^^^^Into unique figurines^^^^~^^^^^^^^~JYJYYYYYJ?JYJJYYYY!^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ^^^^^^^Know^^^^^^^^^^^^^^^^^^^^^^^~^^^^^^~JYYYYJYYYYYYYYY5557^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ^^^^^^^Just Know^^^^^^^^^^^^^^^^~~^^^^^^~?YY55YYJYY55Y?Y5P55Y~^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ^^^^^^^We are all, perfectly imperfect!JYYYYYY?7JY55J~~Y5555Y!^^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~     //
//    ^^^^^^^A collective^^^^^^^^^^^^^^^^~!?JYYYYYJY?^~JYJJY?~?YJ5555Y?!~^^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ^^^^^^^Of Flaws^^^^^^^^^^^^^^^^~!?JYYYYYYYYYJ?7!7YYYYYJ7~7JY555555YJ7!~~^^^~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ^^^^^^^Draped^^^^^^^^^^^^^^~!?JY5YYYYYYYYYYJ!^^~7JJYYYJ?7?YYYYYYYY5555YYJ7!~^^~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~^~^^^In Gold^^^^^^^^^^^~7JYYYYYYYYYY55YJJJ?????JYYYYYY5YYYYYYYYYYYYYYY55YY?!^~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~^^^^^^^^^^^^^^^^^~7JYYYJYYYYYYYYJY55YYYYYYJJJJYYJ??JJYYYYYYYYYYYYYYYY55PJ~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~^^^^^^^^^^^^^~?YYYYYYYYYYYYYY5Y?Y555YYJJJJJJYYJ?77?JYYYYYYYYYYYYJYY5GPY!~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~^^^^^^^^^^^^~JYYJJJJJYJYYJJJY555J??JYYYYYYJJJYYY?77JYYYYYYJJJJJ??J55PP5Y!~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~^^^^^^^^^^^~JYYJJJ7!?JJJJYYYYYYYYYYYJJYJYY5555YYYJJYYYYYY??JJJJJJJJ~5P55Y!~~~~~~~~~~~~!!!!!    //
//    ~~~~~~~~~~~^^^^^^^^^7YYJJJ???JJ?JJJJYYJJYYYYYYYYYJJJJYJY555YYYYYYYJY5Y???7!^7JY555J~~~~~~~~~~!!!!!!!    //
//    ~~~~~~~~~~~~^^^^^^^~JYYYJJJJJJYYYYJJJYJJYYYYYYYYYYYYYYYYJJY5555YYYYYYY?!~:^7~:75555!~~~~~~~!!!!!!!!!    //
//    ~~~~~~~~~~~~~~~~^^^^7YYYYYYYYYYYYJ??JJJJYYYYYYYYYYYYYYYYYYYY5Y5P5YYYYY57:77~~!7555Y~~~~~~~!!!!!!!!!!    //
//    ~~~~~~~~~~~~~~~~~^^^^!JYYY55555YYYJJJJJYYYYJYYYYYYYYYYYYYYYYYYYYYJY5555?YJ?JYY55Y?!~~~~~!!!!!!!!!!!!    //
//    ~~~~~~~~~~~~~~~~^^^^^^^!?J55555YJJJJYYYYYYYYYYYYYYYYYYYYYYYJJJJYYYJYPP5PP5555YY?!~~~~~!!!!!!!!!!!!!!    //
//    ~~~~~~~~~~~~~~~~^^^^^^^^^~7J5YYYJJJJYYYYJJYJJ7?JYYYYYYYYYYJJJJJJYYY5PP5PP55YJ7!~~~!!!!!!!!!!!!!!!!!!    //
//    ~~~~~~~~~~~~~~~~~~^^^^^^^^^~?YYJJJJJJJJJJJJJ???JYYYYYJJ??JJJJJJ?JJYY5P5P55J7~~~~~!!!!!!!!!!!!!!!!!!!    //
//    ~~~~~~~~~~~~~~~~~~^^^^^^^^^^~?YJJJJJJJ~^?JJJJJJYYYYYY?~~~?JJJJ?!!JYY5PY55J!~~~~~~~!!!!!!!!!!!!!!!!!!    //
//    ~~~~~~~~~~~~~~~~^^^^^^^^^^^^^~JYJJJJJJ?7?JJJJJJYYYYYYYJJJJJJJJJ??JJY5YYYY!~~~~~~~~!!!!!!!!!!!!!!!!!!    //
//    ~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^~JJJJJJJJJJJJJJJJYYYYYYYYJJJJJJJJJJJY5YYYY7~~~~~~~~~!!!!!!!!!!!!!!!!!!    //
//    ~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^!JJJJYYJJJJJJJJJYYYYYYYYJJJJJJJJYYYYJJYYJ~~~~~~~~~~!!!!!!!!!!!!!!!!!!    //
//    ~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^7YYJYYYYYJJJJJJYYYYYYYYJJJJYYYYY5YJJYYY!~~~~~~~~~~!!!!!!!!!!!!!!!!!!    //
//    ~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^?YYYYYYYYYYYYYYY55555YYYYYYYYY5YJYYYY?~~~~~~~~~~~~!!!!!!!!!!!!!!!!!    //
//    ~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^?YYYYYYYYYYYYYY555YYYYYYY5555YYYYYYY!^~~~~~~~~~~!~!!!!!!!!!!!!!!!!    //
//    ~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^!JYYYYYYYYYYYYYYYYYYYYYYY55JYY55YYYJ~~~~~~~~~~~~~~!!!!!!!!!!!!!!!!    //
//    ~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^!YYYYYYYYYYYYYYYYYYYYYYY55JY5YYYYYY?^~~~~~~~~~~~~~~!!!!!!!!!!!!!!!    //
//    ~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^!YYYYYYYYYYYYYYYYYYYYYY5PYYYYYYYYYY?^~~~~~~~~~~~~~~!!!!!!!!!!!!!!!    //
//    ~~~~~~~~~~~~~~~~^^^^^^^^^~~^~^^^^^~JYYYYYYYYYYYYYYYYYYY555YYYJYYYYYYYJ~^~~~~~~~~~~~~~!!!!!!!!!!!!!!!    //
//    ~~~~~~~~~~~~~~~~~^^^^^^^^~~^^^^^^^~JYYYYYYYYJYYYYYYYYY5PP5Y5YYYYYYYYY57^^~~~~~~~~~~~~!!!!!!!!!!!!!!7    //
//    ~~~~~~~~~~~~~~~~~~^~~^^~~^^^^^^^^^!JYYYYYYYYYYYYYYJJY5PPP5YYYYJJYY5555Y!^^~~~~~~~~~~~!!!!!!!!!!!!777    //
//    ~!~!~~~~~~~~~~~~~~~~~~~^^^^^^^^^^~JYJJYYYYYYYYYYYJJJYPGGPP55YYYJYY55555Y!^~~~~~~~~~~!!!!!!!!!!!!!!77    //
//    !!!!~~~~~~~~~~~~~~~~~~~~^^^^^^^^~JYYYJYYYYYYYYYYJJJY5PGGGPPYYYYYYYYY5555Y!^~~~~~~~~~!!!!!!!!!!!!!!!7    //
//    !!!!!!~~~~~~~~~~~~~~~~~~^^^^^^^~?YYYYYYYYYJYYYYYJJJYPGGGGGP5YYYYYYYYY5555Y!^~~~~~~~!!!!!!!!!!!!!!!!!    //
//    !!!!!!!~~~~~~~~~~~~~~~~~~~^^^^^7YYYYYYYYYYJJYYYYJJY5PPGGGGGP5YYYYYYYYY5555Y!~~~~~~!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!~~~~~~~~~~~~~~~~~~~^^^!JYYYYYYYYYJJJJJYYYYY555PGGGP55YYYYYYYYYY5555J~~~~~!!!!!!!!!!!!!!!!!!7    //
//    !!!!!!!!!!!~~~~~~~~~~~~~~~~~^^?YYYYYYYYYYJJJJJYY5YYYYJYY5555YYYYYYYYYYYY555Y!~~~~!!!!!!!!!!!!!!!!!77    //
//    !!!!!!!!!!!~~~~~~~~~~~~~~~~~^!YJYYYYYYY5YYYYYYYYYYYYYYJJJJJY5YYYYYYYYYYYY55Y?~~~!!!!!!!!!!!!!!!!7777    //
//    !!!!!!!!!!!!~~~~~~~~~~~~~~~~^?YYYYYYYYJ?JJYYYYJYJJJJJJJJJYYYYYYYYYYYYYYYY55YJ~~!!!!!!!!!!!!!77777777    //
//    !!!!!!!!!!!!!~~~~~~~~~~~~~~~!YYYYYYJ77JY555YYJJJJJYYYYYJYYYJYYYYYYYYYYYYY55YJ~~!!!!!!!!!!!7777777777    //
//    !!!!!!!!!!!!!!!!~~~~~~~~~~~~7YYYYJJJJ5YYYYYYYYJJJYYYYYYYYYY?Y5YYYYYYYYYYYY5YJ~!!!!!!!!!!!!!!77777777    //
//    !!!!!!!!!!!!!!!!~~~~~~~~~~~~?JJJYYYYYYYYYYY55YYYYYJJJJJYY5Y?Y5YYYYYYYYYYYYYYJ~!!!!!!!!!!!!!777777777    //
//    !!!!!!!!!!!!!!!!!!!~~~~~~~~~7Y55YYJJJJYYYYYY5YYYYYYJJJJYY55?55YYYYYYYYYYYYYY?~!!!!!!!!!!!!7777777777    //
//    !!!!!!!!!!!!!!!!!!~~~~~~~~~~~YYYYYYJJJJYYYYYYYY5YYYYJJJYYY5?55YYYYYYYYYYYYYY?!!!!!!77!!!777777777777    //
//    !!!!!!!!!!!!!!!!!!!~~~~~~~~~~75YYYYJJJJJYYYYYYYYYY5YYYYYYYYJG5YJYJYYYYYYYYYY7!!!!!!77777777777777777    //
//    !!!!!!!!!!!!!!!!!!!~~~~~~~~~~!Y5YYYYJJJJJYYYYJJJYY5555YYYYYJP5YJYYYYYYYYY55Y!!!!!!777777777777777777    //
//    !!!!!!!!!!!!!!!!!!!~~~~~~~~~~~JY5YYYYYYYYYYYJJJJJYY5555YYYYJP5YYYYYYYYJYY55?!!!!!!777777777777777?77    //
//    !!!!!!!!!!!!!!!!!!!!~~~~~~~~~~7YYYYYYYYJYYJYYJJJJJYY555YYJYJ55YYYYYYYYJYY5Y7!!!!!77777777777777???77    //
//    !!!!!!!!!!!!!!!!!!!!~~~~~~~~~~!YYJJYYYYYJJJYYYYJJJJY555YYJJJ55YYYYYYYJYY55Y!!!!!777777777777777????7    //
//    !!!!!!!!!!!!!!!!!!!!!~!~~~~~~~~?YYYJYYYYYYYYYYYJJJYY555YYJJYYPYYYYYYJJYY55?!!!!!777777777777777777?7    //
//    !!!!!!!!!!!!!!!!!!!!!!!~~~~~~~~!YYYYJ55YYYYYYYYYJJYY555YYJJYJ5YYYYYYJJYY5Y7!!!!777777777777777777??7    //
//    !!!!!!!!!!!!!!!!!!!!!!!~!~~~~~~~JYYYYJ5YYJYYYYYYJJYY5555YJJYJ5YYYYYJJYY55J!!!!7777777777777777777777    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!~~~~~~~7YYYYYJPYJJYYYYYJJYY5555YJJYY55YYYJJJYY55?!!!!7777777777777777777777    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!~~~~~~~JYYYYJ55YYJYYYYJJYY5555YYJYYYP5YYJJJY55Y7!!!!7777777777777777777777    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!~~~~~~~7YYYYYJP5YJJYYYYYYY5555YYJJYJ55YJJJYY55J!!!!77777777777777777777777    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!~~~~~~!JYYYYJYPYJJJJJJYYYe5555YYJYJJ5YYJJYY5Y?!!!!77777777777777777777777    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!~~~~~~?YYYYYJ55YJJJJJJYYm5555YYJYY?JYYJJYY5Y7!!!777777777777777777777777    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~~~~!JY5JYYYPYYJJJJJYYo55555YJYY?YYYJYY55J!!!!777777777777777777777777    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~~~~~?YJY5YYYPYYJJJJYYM55555YYYJJYYJJYY55?!!!!777777777777777777777777    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~!~~~?JY5YYYYYPYJJJJJYYY5555YYYJYYJJJYY55?!!!!777777777777777777777777    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~~~7J5YYYJJY55YYJJJJYYYY55Y5JJYJJJJY55Y7!!!!777777777777777777777777    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~~!YYYYYYJJYY5YJJJJYY5Y5555JYYJJJJYY5Y!!!!7777777777777777777777777    //
//    !!!!!!!!!!!!!!!!!!!!!!7!!!!!!!!!!~~!JYYYYYJJJYYYYJJJY5555P55YJYYYJJY55J!!!!777777777777777777777777!    //
//    !!!!!!!!!!!!!!!!!!7!!!7!!!!!!!!!!!!!JYYYYYYJJYYJJJYY55YYYYYJJ?JYYYYY55?!!!!7777777777777777777777777    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!77!!!!!!!!?YYYYYYYY5JJ??JJJ?77!7?????YYYYY5Y7!!!77777777777777777777777777    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!77777!!!!!!?JYYYYYYYYJYJJJJJJY55YJJJJ?YYYYY5Y!!!!77777777777777777777777777    //
//    !!!!!!!!!!!!!!!!!!!!!!77777777777!!!?JYYYYYYYJY5YYYYY555P555Y5YJ5YYY5J!!777777777777777777777777777!    //
//    !!!!!!!!!!!!!!!!!!!!!!!777777777777!?YYYYYYYJJYYJJJYYY55555YYYYJY555Y?!!777777777777777777777777777!    //
//    !!!!!!!!!!!!7!!!!!!!!!!777777777777!?YYYJJJYYYYJJJJJYY55555YYJYYJY55Y?!77777777777777777777777777777    //
//    !!!!!!!!!!777!!!!!!77777777777777777?YYYYYYYYYYJJJJYYY5555YYJJJYYJJY5J77777????????????????????77777    //
//    !!!!!!!!!7!7!!!777777777777777777777?YYYYYYYYYYJJJJYYY5555YYJJJY5J?JYJ777?????????????????????777777    //
//    !!!!!!!7!777777777777777777777777777?YYYYYYYYYJJJJJYYY5555YYJJJYYJYYYY?7????????????????????77777777    //
//    !!!!!!!77777777777777777777777777777?YYYYYYYYYYJJJJYYY5555YYJJJYJY55YYJ77??????????????????777777777    //
//    !!!!!!!!7777777777777777777777777777JYYYYYYYYYYJJJJYYYY555YYJJJYJYYYYYY?7?????????????????7777777777    //
//    !!!!!!!!!777777777777777777777777777JYYYYYYYJJYJJJJYYYY555YYJJYY?Y55YYYJ77???????????????77777777777    //
//    !!!!!!!!!!!777777777777777777777777JYJYYYYYYJJYJJJJJYYY555YYJJYY??YYYYYYJ????????????????77777777777    //
//    !!!!!!!!!!!!!777777777777777777777JJYJYYYYYJJYYYJJJJYYY55YYYYJYJ?JJYJJJYYY?????????????77777777777!!    //
//    ~~!!!!!!!!!!!!7777777777777777777JJYYJYYYYYJJJYYYJJJJYY55YYYYYY??YYY5YYJYYY??????????777777777!!!!!!    //
//    ~~~!!!!!!!!!!!!!7777777777777777JYJYJYYYYYYJJJYYYJJJJYY555YYYYY7JJJJYY5555YJ??????7777777!!!!!!!!!!!    //
//    ~~~!!!!!!!!!!!!!!!!777777777777JYYYJJYYYYYYJJYYYYYJJJJYY5YYYY5J?YJJJYYY5555Y????7777!!!!!!!!!!!!!!!!    //
//    ~~!!!!!!!!!!!!!!!!!!!!77777777JYY5YJJYYYYYJJJYYYYYJJJJYY55PPPY?YYYJJYYY555YYJ??777!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!77777JY55YYYYYYYJJJJJYYYYJJJJY5PP5YJ~??JYYYYYY555YJ?77!7!!7!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!777JY55YYYYYYYYJJJYYYYYJJJJYY?77!^~!!7JY55YY55YJ?777777777!!!7!!7!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!77JYYY5YYYYYYYYYYYYYYYYYJJ?!!JJ:JY555YYYYYYJ?777777777!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!7?JYYYYYYYYYYYYYYYYYYY5YYY5PP?5P5YYYYJJ?7777777!!777!!!!!!!!!!!!!!!!!    //
//    ~~!~~~~~~~~!!!!!!!!!!!!!!!!!!!!!!!7?JYYYYYYYYYYYYYYYYYYYY55JJYJJ??777777777777777!!!!!!!!!777!7777!!    //
//    ~~!!~~~!!THE!!!!!!!!!!!!!!!!!!7!!!!!!!7??JJJJJYYYYYYJJJJJ??77777777777777777!J5?Y!!77!77!7JJP?YJY?!!    //
//    ~~!!~~!COMPLETELY!!!!!!!!7!7!!7!7!7!!!!7!7!77777777?777777777777777777777777!?PP5!!7Y5J!!!!7J7!!!!!!    //
//    ~~!!!!!!!FLAWED!!!!!!!!!!7!!!!7!777!!!77!!!777777777777777?777?7777777777777!JY?Y7!7JJ57!!Y5J?!!!!!!    //
//    !~~~!~!!!!COLLECTION!!!!!!!!!!!!!!!!!!!!!!!!!777777777777777777777777777777!!!!7!!!77!!!!!!!!!!!NEF!    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CFC is ERC721Creator {
    constructor() ERC721Creator("THE COMPLETELY_FLAWED COLLECTION", "CFC") {}
}