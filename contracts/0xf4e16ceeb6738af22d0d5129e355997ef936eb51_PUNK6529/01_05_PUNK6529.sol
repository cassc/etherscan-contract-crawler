// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Freedom to produce memes
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^    //
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^    //
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^    //
//    ^^^^^^^JYJY!^JJJY7^7Y?J7^?YJ7^^^^^~JJ7J~~YJ7J7^^?J7J7^JY?JJ^^7Y7J?^?Y?!^^^^^^^^^!55^YP?~^^^^^J!~J7?J~^^^^!7~JJ?Y~^^^^^^^    //
//    ^^^^^^[email protected]@@@[email protected]@@@5:[email protected]@@&^&@@@&7^^^[email protected]@@@[email protected]@@@G^^&@@@[email protected]@@@&^^&@@@&^#@@@&J^^^^^!#@@&^[email protected]@&?^^^^@#[email protected]@@@?^^^^##[email protected]@@@?^^^^^^^    //
//    ^^^^^^^&@@@[email protected]@@@5:[email protected]@@&^&@@@@@7^^[email protected]@@@[email protected]@@@G^[email protected]@@@[email protected]@@@&^^[email protected]@@&^#@@@@@J^^^[email protected]@@@&^#@@@@?^^^&@~&@@@P^^^^@#[email protected]@@@7^^^^^^^    //
//    ^^^^^^^#@@@P^J??J!^[email protected]@@#^[email protected]@@@#^^[email protected]@@@J~YJ?Y7^^&@@@B^JY?Y?^^[email protected]@@@[email protected]@@@@~^^[email protected]@@@Y^[email protected]@@@#^^^&@[email protected]@@#^^^[email protected]@@@@!^^^^^^^    //
//    ^^^^^^[email protected]@@@P^^^^^^^[email protected]@@#^^^&@@@G^^[email protected]@@@J^^^^^^^[email protected]@@@B^^^^^^^^[email protected]@@&~^:[email protected]@@@J^^&@@@#^^:[email protected]@@@!^^&@#[email protected]@@@7^^[email protected]@@@@Y^^^^^^^    //
//    ^^^^^^[email protected]@@@P^^^^^^^[email protected]@@&^^^&@@@B^^[email protected]@@@J^^^^^^^~&@@@B^^^^^^^^#@@@#^^^[email protected]@@@5^[email protected]@@@5^^^[email protected]@@@J^^#@@[email protected]@@P^^&@[email protected]@@@J^^^^^^^    //
//    ^^^^^^[email protected]@@@G^??7?~^[email protected]@@&^[email protected]@@@P^^[email protected]@@@J~J??J~^[email protected]@@@B^JJ7J!^^[email protected]@@@~^^[email protected]@@@#:[email protected]@@@G^^^[email protected]@@@?^^#@@[email protected]@@#^[email protected]@[email protected]@@@?^^^^^^^    //
//    ^^^^^^^&@@@[email protected]@@@!:[email protected]@@#^#@@@@B~^^[email protected]@@@[email protected]@@@!^^[email protected]@@[email protected]@@@5^^[email protected]@@@~^^^&@@@#^[email protected]@@@5^^^[email protected]@@@!^^&@@P^@@@&^[email protected]@[email protected]@@@7^^^^^^^    //
//    ^^^^^^^&@@@[email protected]@@@7:[email protected]@@G^&@@@G!^^^[email protected]@@@[email protected]@@@!^^&@@@[email protected]@@@J^^[email protected]@@@~^^[email protected]@@@#^[email protected]@@@5^^^[email protected]@@@?^^&@@&^#@@@[email protected]@[email protected]@@@Y^^^^^^^    //
//    ^^^^^^[email protected]@@@G^YYJY~^[email protected]@@&^#@@@@@7^^[email protected]@@@J!YY?Y~^^&@@@B^YY?Y!^^[email protected]@@&^^^[email protected]@@@G^[email protected]@@@5^^^[email protected]@@@J^^#@@@[email protected]@@7#@@[email protected]@@@Y^^^^^^^    //
//    ^^^^^^[email protected]@@@G^^^^^^^[email protected]@@&^^7&@@@G^^[email protected]@@@J^^^^^^^^&@@@B^^^^^^^^[email protected]@@@~^^[email protected]@@@G:[email protected]@@@5^^^[email protected]@@@J^^&@@@P^@@@?&@@[email protected]@@@7^^^^^^^    //
//    ^^^^^^[email protected]@@@G^^^^^^^#@@@&^^^[email protected]@@#^^[email protected]@@@J^^^^^^^^&@@@B^^^^^^^^[email protected]@@@~^^[email protected]@@@5^[email protected]@@@P^^^[email protected]@@@7^^&@@@G^&@@J&@@[email protected]@@@!^^^^^^^    //
//    ^^^^^^~&@@@G^^^^^^^#@@@#^^^[email protected]@@&^^[email protected]@@@J^^^^^^^^&@@@B^^^^^^^^[email protected]@@@~^~#@@@@!^^[email protected]@@@~^^#@@@&^^^#@@@G:[email protected]@?&@#^[email protected]@@@?^^^^^^^    //
//    ^^^^^^~&@@@P^^^^^^^[email protected]@@B^^^[email protected]@@&^^[email protected]@@@J7&&#&B^^&@@@B~#&&&&!:[email protected]@@@^[email protected]@@@@G^^^[email protected]@@@#^[email protected]@@@G^^^#@@@P:[email protected]@[email protected]@5:[email protected]@@@?^^^^^^^    //
//    ^^^^^^[email protected]@@@P^^^^^^^#@@@&^^^[email protected]@@&~^[email protected]@@@[email protected]@@@&^[email protected]@@@[email protected]@@@@!:[email protected]@@&^[email protected]@@@P^^^^^[email protected]@@@^[email protected]@@#~^^^@@@@G^[email protected]@@@@!^[email protected]@@@?^^^^^^^    //
//    ^^^^^^~#&B&5^^^^^^^B&#&G^^^?&#&&!^7&&#&!?&&#&#^~#&#&Y~&&#&&!^5&#&B^G&#P7^^^^^^^7#@&^[email protected]#Y^^^^^#&#@5^^P&#&B^^!#&#&7^^^^^^^    //
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~^^^^^^^^^^:^^^^^^^:^^^^^^^^^~~^~~^:^^^^^^^^^^^^^^^:^^^^^^:^^^^^^^^^    //
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~&PG&Y#B^[email protected]#&7^^^~&&J&#J^5&PP&G~^^?&GP&?^7&#?&B?^~B#?^Y#P^^J5JG!^Y#5Y#B~^^^^^^^    //
//    ^^^^^^^^^^^^^!7??!~!!~^^^^^~7~^^^^^^^^^^~5?&@[email protected]@[email protected]&^^^[email protected]@[email protected]@[email protected]@@B^[email protected]@[email protected]@[email protected]@?#@@[email protected]@J:[email protected]&^[email protected]&[email protected]@^[email protected]#Y&B~^^^^^^^    //
//    ^^^^^^^^^^^!JYYYY7^~7?!^^~?JY~^^^^^^^^^^^^^&@5::[email protected]:[email protected]@!^^[email protected]@?:&@[email protected]#:[email protected]#:[email protected]@[email protected]@[email protected]@!^&@[email protected]@J:[email protected]&~&@Y^&@[email protected]&::^^^^^^^^^    //
//    ^^^^^^^^^^!YYYYYY7^^^^~!JYYYY~^^^^^^^^^^^^^#@5^^[email protected]^[email protected]@[email protected]@[email protected]@[email protected]@@Y:[email protected]&^^&@[email protected]@7:#@[email protected]@?:[email protected]#^@@?^~~^[email protected]#JB5^^^^^^^^    //
//    ^^^^^^^^^^7YYYYYY7^^?7~!?!!YY~^^^^^^^^^^^^^#@Y^^[email protected][email protected]@[email protected]@G##PJ#@[email protected]@?:[email protected]&^[email protected]@[email protected]@7^#@[email protected]@?:[email protected]&[email protected]@J^^^^[email protected]#5&G^^^^^^^^    //
//    ^^^^^^^^^^~JYYYYY7^^JYJ~^^!YY~^^^^^^^^^^^^^[email protected]^^[email protected][email protected]@[email protected]@GYYYY&@#^[email protected]#:[email protected]@^^@@[email protected]@7:&@[email protected]@?:[email protected]&[email protected]@?^P#[email protected]&^^^^^^^^^^^    //
//    ^^^^^^^^^^^~7JYYY7^^?7~^^^!YY~^^^^^^^^^^~?7#@[email protected]@[email protected]&[email protected]@5!!!!#@#[email protected]&[email protected]@[email protected]@[email protected]@[email protected]@?^&@#[email protected]@P:#@[email protected]@[email protected]#!J?~^^^^^^^    //
//    ^^^^^^^^^^^^^~~!7~^^^^^^^^~77~^^^^^^^^^^!YY#@[email protected]#&7^^^~&@?^^^^[email protected]#[email protected]&[email protected]&&@5^[email protected]@[email protected]&Y^^7&@[email protected]~^7&&[email protected]^[email protected]@@!^^^^^^^    //
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~~~~7JJJJJJJJJYJ~^^^^^^~~^^^^^~~?JJYYJJJYYY?^~~!!~~^^^^^^!~~^^^^^~~~^^~!~~!!~^^^^^^^    //
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~JYYYYJ~~~~~~~~~~~^^^^^^^^^^^^^^^^~~~~~~~~~~~?YYYJJ~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^    //
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^JYYYYJ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^?YYYYY~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^    //
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~77777?77777^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^!7777?77777!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^    //
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^!YYYYY!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~YYYYY7^^^^^^^^^^^^^^^^^^^^^^^^^^^^^    //
//    ^^^^^^^^^^^^^^^^^^^^^^^^^~~~^!YYYYY!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~YYYYY7^~~~~^^^^^^^^^^^^^^^^^^^^^^^^    //
//    ^^^^^^^^^^^^^^^^^^^^^^^~?JJJJ?~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~~~~?JJJJJ~^^^^^^^^^^^^^^^^^^^^^^^    //
//    ^^^^^^^^^^^^^^^^^^^^^^^^JYYYYJ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^?YYYYY~^^^^^^^^^^^^^^^^^^^^^^^    //
//    ^^^^^^^^^^^^^^^^^^~!!!!!?????7^^^^^^^^^^~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~^^^^^^^^^^7?????7!!!!~^^^^^^^^^^^^^^^^^^    //
//    ^^^^^^^^^^^^^^^^^^7YYYYY!^^^^^^^^^^^^^^^!YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY7^^^^^^^^^^^^^^^~YYYYY?^^^^^^^^^^^^^^^^^^    //
//    ^^^^^^^^^^^^^^^^^^7YYYYY!^^^^^^^^^^^^^^^!YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY7^^^^^^^^^^^^^^^~YYYYY?^^^^^^^^^^^^^^^^^^    //
//    ^^^^^^^^^^^^^^^^^^7YYYYY!^^^^^^^^^^??????!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!??????~^^^^^^^^^~YYYYY?^^^^^^^^^^^^^^^^^^    //
//    ^^^^^^^^^^^^^^^^^^7YYYYY!^^^^^^^^^^JYYYYJ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^?YYYYY~^^^^^^^^^~YYYYY?^^^^^^^^^^^^^^^^^^    //
//    ^^^^^^^^^^^^^^^^^^7YYYYY!^^^^~~~~~!?JJJJ?!~~~~~~~~~~~~~~~~~~~~~^^^^^~~~~~~~~~~~?YYYYJ!~~~~~^^^^~YYYYY?^^^^^^^^^^^^^^^^^^    //
//    ^^^^^^^^^^^^^^^^^^7YYYYY!^^^^!YYYYY!^^^^!YYYYYYYYYYYYYYYYYYYYYJ~^^^^?YYYYYYYYYYYYYYYYYYYYY7^^^^~YYYYY?^^^^^^^^^^^^^^^^^^    //
//    ^^^^^^^^^^^^^^^^^^7YYYYY!^^^^!YYYYY!^^^^!YYYYYYYYYYYYYYYYYYYYYJ~^^^^?YYYYYYYYYYYYYYYYYYYYY7^^^^~YYYYY?^^^^^^^^^^^^^^^^^^    //
//    ^^^^^^^^^^^^~7?????77777~^^^^!YYYYY?7??7?YYYYY?7777777777JYYYYJ?????JYYYYJ77777777777YYYYY7^^^^~77777?????7~^^^^^^^^^^^^    //
//    ^^^^^^^^^^^^~JYYYY?^^^^^^^^^^!YYYYYYYYYYYYYYYY!^^^^^^^^^^?YYYYYYYYYYYYYYYJ~^^^^^^^^^~YYYYY7^^^^^^^^^^7YYYYY~^^^^^^^^^^^^    //
//    ^^^^^^^^^^^^~JYYYY?^^^^^~~~~~7YJJJJJJJJJYYYYYY!^^^^^^^^^^?YYYYYJJJJJYYYYYJ~^^^^^^^^^~YYYYY?~~~~~^^^^^7YYYYY~^^^^^^^^^^^^    //
//    ^^^^^^^^^^^^~JYYYY?^^^^~JYJJY?~~~~~~~~~~7YYYYY!^^^^^^^^^^?YYYYJ~~~~~?YYYYJ~^^^^^^^^^~YYYYYYJJJJJ~^^^^7YYYYY~^^^^^^^^^^^^    //
//    ^^^^^^^^^^^^~JYYYY?^^^^~JYYYYJ^^^^^^^^^^!YYYYY!^^^^^^^^^^?YYYYJ~^^^^?YYYYJ~^^^^^^^^^~YYYYYYYYYYY~^^^^7YYYYY~^^^^^^^^^^^^    //
//    ^^^^^^^^^^^^~JYYYY?^^^^~JYYYYJ^^^^^^^^^^!YYYYY?7777777777JYYYYJ~^^^^?YYYYJ77777777777YYYYYYYYYYJ~^^^^7YYYYY~^^^^^^^^^^^^    //
//    ^^^^^^^^^^^^~JYYYY?^^^^~JYYYYJ^^^^^^^^^^!YYYYYYYYYYYYYYYYYYYYYJ~^^^^?YYYYYYYYYYYYYYYYYYYYYYYYYYJ~^^^^7YYYYY~^^^^^^^^^^^^    //
//    ^^^^^^^^^^^^~JYYYY?^^^^~JYYYYJ~^^^^^^^^^!YYYYYYYYYYYYYYYYYYYYYJ~^^^^?YYYYYYYYYYYYYYYYYYYYYYYYYYJ~^^^^7YYYYY~^^^^^^^^^^^^    //
//    ^^^^^^^!JJJJJ7~~~~7JJJJJYYYYYYJJJJJ!~!!!!777777777777777~~~~~~~^^^^^~~~~~~~~~~~~~~~~!YYYYYYYYYYYJJJJJ?~~~~!JJJJJ7^^^^^^^    //
//    ^^^^^^^7YYYYY!^^^^7YYYYYYYYYYYYYYYY7&#GGGGGGGGGGGGGGGGG5^^^^^^^^^^^^^^^^^^^^^^^^^^^^~YYYYYYYYYYYYYYYY?^^^^~JYYYY?^^^^^^^    //
//    ^^^^^^^7YYYYY!^^^^[email protected]#PGGGGGGGGGGGGGGG##^^^^^^~!!!!!!!!!!!^^^^^^^^^^~YYYYYYYYYYYYYYYY?^^^^~JYYYY?^^^^^^^    //
//    ^^^^^^^7YYYYY!^^^^7YYYYYYYYYYYYYYYY7BBGGGGGGGGGGGGGGGGBB^^^^^^!YYYYYYYYYYJ~^^^^^^^^^~YYYYYYYYYYYYYYYY?^^^^~JYYYY?^^^^^^^    //
//    ^^^^^^^7YYYYY!^^^^7YYYYYYYYYYYYYYYY7BBGGGGGGPGGPGGGGGGBB^^^^^^!YYYYYYYYYYJ~^^^^^^^^^~YYYYYYYYYYYYYYYY?^^^^~JYYYY?^^^^^^^    //
//    ^^^^^^^7YYYYY!^^^^7YYYYYYYYYYYYYYYY7&BGGGGGG#?Y#GGGGGP##^^^^^^~!!!!!!!!!!!^^^^^^^^^^~YYYYYYYYYYYYYYYY?^^^^~JYYYY?^^^^^^^    //
//    ^^^^^^^7YYYYY!^^^^[email protected]&GGGGGGGY^^^^^^^^^^^^^^^^^^^^^^^^^^^^~YYYYYYYYYYYYYYYY?^^^^~JYYYY?^^^^^^^    //
//    ^^^^^^^7YYYYY!^^^^7YYYYYYYYYYYYYYYY7GGGGGGGGP55PGGGGGGGP^^^^^^^^^^^^^^^^^^^^^^^^^^^^~YYYYYYYYYYYYYYYY?^^^^~JYYYY?^^^^^^^    //
//    ^^^^^^^7YYYYY!^^^^[email protected]#PGGGGGGGGGGGGGGP#@^^^^^^^^^^^^^^^^^^^^^^^^^^^^~YYYYYYYYYYYYYYYY?^^^^~JYYYY?^^^^^^^    //
//    ^^^^^^^7YYYYY!^^^^7YYYYYYYYYYYYYYYY!PGGGGGGGGGGGGGGGGG&&^^^^^^^^^^^^^^^^^^^^^^^^^^^^~YYYYYYYYYYYYYYYY?^^^^~JYYYY?^^^^^^^    //
//    ^^^^^^^7YYYYY!~~^~7YYYYYYYY5Y5YYYYY!?J55YPYJP5Y55JJJJJJ?77?J?JJ77777???JJJ7^^^^^^^^~7Y5YY55YY5YYYYYYY?^^^^~JYYYY?^^^^^^^    //
//    ^^^^^^^[email protected][email protected]&@#[email protected]&@@@&YYYY!^[email protected]@@@[email protected]@@@B:^^^^:[email protected]@@@@[email protected]@@@@~^^^^^^^#@@@#[email protected]@@@@YYYYYYY?^^^^~JYYYY?^^^^^^^    //
//    ^^^^^^^[email protected]@@@@[email protected]#@@@&YYYY!^[email protected]@@@[email protected]@@@#^^~~~^[email protected]#[email protected]@@@[email protected]@@@@~^^^^^^^&@@@#[email protected]@@@@YYYYYYY?~~~~~JYYYY?^^^^^^^    //
//    ^^^^^^^[email protected]#[email protected]@@@[email protected]#@@@#JYYY!^[email protected]@@@Y~GP5GY^^[email protected]&[email protected]@@[email protected]@@@&^^^^^^^^#@@@&Y#&#&#YY!~~~~?JJJJJ!~~~~~^^^^^^^    //
//    ^^^^^^^^^^^[email protected]@5#@@@P^^[email protected]@Y&@@@&YYYY!^[email protected]@@@5^^^^^^^^[email protected]@[email protected]@@&^^^&@[email protected]@@@!^^^^^^^&@@@&JYYYYYYY~^^^^7YYYYY~^^^^^^^^^^^^    //
//    ^^^^^^^^^^^[email protected]@#[email protected]@@&^^[email protected]@Y#@@@@YYYY!^[email protected]@@@5^^^^^^^^[email protected]@&[email protected]@@@7^[email protected]@[email protected]@@@!^^^!!!!&@@@&JYJ?????7!!!!??????~^^^^^^^^^^^^    //
//    ^^^^^^^^^^^[email protected]@#J&@@@7:[email protected]@Y#@@@&JYYY!^[email protected]@@@5^7!!7~^^^^^^[email protected]@&^[email protected]@@Y:[email protected]@[email protected]@@@~^^^[email protected]@@@&J5?^~~^~YYYYY?^^^^^^^^^^^^^^^^^^    //
//    ^^^^^^^^^^^[email protected]@&[email protected]@@7^&@@5&@@@&YYYY!^~&@@@[email protected]@@@?^^^^^^[email protected]@@[email protected]@@5^#@@[email protected]@@&~^^^?YYY&@@@#[email protected]@&@5^~YYYYY?^^^^^^^^^^^^^^^^^^    //
//    ^^^^^^^^^^^[email protected]@@[email protected]@@[email protected]@@!&@@@&YYYY!^[email protected]@@@[email protected]@@@!^^[email protected]@@[email protected]@@&[email protected]@@[email protected]@@@Y?JJYYYJ&@@@[email protected]@@@G?J!!!!!~~PB?&Y^^^^^^^^^^^^    //
//    ^^^^^^^^^^^[email protected]@@[email protected]@@&[email protected]@@~#@@@@YYYY!^[email protected]@@@Y!GG5G!^^[email protected]@@@Y&@@@[email protected]@@[email protected]@@@5YYYYYYY&@@@B^B##&GYY~^^^^^[email protected]#[email protected]@J^^^^^^^^^^^    //
//    ^^^^^^^^^^^[email protected]@@&^[email protected]@&[email protected]@&^[email protected]@@&YYYY!^[email protected]@@@5^^^^^^^^[email protected]@@@[email protected]@@[email protected]@@[email protected]@@@JJJJJJJJ&@@@#~~7??JJ?~^^^^^&@B^PB?^^^^^^^^^^^    //
//    ^^^^^^^^^^^[email protected]@@@[email protected]@&[email protected]@G:[email protected]@@BJYYY!^[email protected]@@@5^^^^^^^^[email protected]@@@[email protected]@@[email protected]@&^[email protected]@@#^^^^^^^^&@@@&YY7^^^^^^^^^^^[email protected]@&J^^^^^^^^^^^^^    //
//    ^^^^^^^^^^^[email protected]@@@[email protected]@&[email protected]@J:#@@@&YYYY!^[email protected]@@@5^^^^^^^^[email protected]@@@[email protected]@@[email protected]@P:[email protected]@@@~^^^^^^^&@@@&YY7^^^^^^^^^^^:7#@@#~^^^^^^^^^^^    //
//    ^^^^^^^^^^^[email protected]@@@~^&@&[email protected]@7^#@@@&YYYY!^[email protected]@@@Y~B#GBG~^[email protected]@@@PJ#@@[email protected]@[email protected]@@@????????&@@@#!BBPPG!^^^^^^^[email protected]@P^^^^^^^^^^^    //
//    ^^^^^^^^^^^[email protected]@@@~^[email protected]@@@&!^#@@@&YYYY!^[email protected]@@@[email protected]@@@&~^[email protected]@@@[email protected]@@@&[email protected]@@@[email protected]@@@G^@@@@@7^^^^^^^&@[email protected]@5^^^^^^^^^^^    //
//    ^^^^^^^^^^^[email protected]@@@!^[email protected]@@@G~^[email protected]@@&JJJJ!^[email protected]@@@[email protected]@&@&~^[email protected]@@@PJJ&@&@[email protected]@@&[email protected]@@@[email protected]@@@@7^^^^^^^[email protected]&[email protected]#~^^^^^^^^^^^    //
//    ^^^^^^^^^^^~7!!7^^^!!~!~^^~!~!!^~~~^^^~~~~^~!~~~~^^^~~~~!~~!~~^~~^~^^~^~~~~~~~~~~~~!7!!~^77!!7~^^^^^^^^~!~!^^^^^^^^^^^^^    //
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^    //
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^    //
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PUNK6529 is ERC1155Creator {
    constructor() ERC1155Creator("Freedom to produce memes", "PUNK6529") {}
}