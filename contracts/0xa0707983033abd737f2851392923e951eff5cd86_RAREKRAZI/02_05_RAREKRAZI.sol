// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RARE KRAZI
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ~~!7~?JYYYYYJ??7!!?J??JJ?!77!!77??JJYYYJJYYYY5555Y7?!!~!!!~~~!!!~~~!~777!!7^!!~!~?!!7!!~~!!777?. ..~    //
//    ^^^7~!?JJJJJ77775BGBG5?J?7~!???7?J5PP55555PPPPP55J~!!~~~!~~~^!Y7!~J7^~7!~~!~7?JJYJYJ7!~~~~^~::!:...:    //
//    ^^~7!77???YJ???7JYJJJY???777?77YPPGGGGGGGBBBBBGGGY^^^^^^^~~^^!?7!7J!:^:::^^!YPPPG5YJPY7~!~~!!:7J????    //
//    ^^^77J???J5?5YY??!~~~~!!!7?7777JJJYYYY5PPPGBBBBBBG?J?~:^~!7^~J?!J5Y!:^:::^^7Y555PY!P5?^:.^7757?7!77?    //
//    ^::7JYYJ!JY5557!?7!~~~!!77?~7?~^!!~7!~777???JJY5PPJ7?^^77Y57~?7?J5JP:^!7^^^^^~!JP5?YP5!!^77?J!?:.:^~    //
//    :::!Y55Y!?555P5JJ5Y5PG5^!!7~~7!7!!~?!^?7^~~^~!!!7?JJ?^!!7Y5P5J75PYPB!!~?J!~~^^^?55YYJ5??5Y!J?~~^:::!    //
//    :::!Y555J77YYY55YY5PBBB7!7??JJJJ77??77J?7~!!!!~~7?Y???J?7!YYYY5PPBB5!75Y?!!77!~~!!~7J7~?P575?J:.:.~~    //
//    :.^!J555Y:JJJJ5555PGB#GY??777??J5?!!?!^J7!577J7??J5J????!~?JJY5PG#57J7~^^^^~!~?7^~^~??!77??JJP!.::~     //
//    :.^77555! ?JJJJYYPG##J!!!!!!!!!~!5Y~7777^^!!?P5YJJYJ7!?7~!JJY5PGBP~^^:....:~!~!7?!~~?7!!:^!??5?.:~^:    //
//    ::^7!55~^^7?YYYPGGBB!^^:^!!!!!~^~~5J!!JY!7JPGGPP5YYYYJYJ?!YYPGGB57!!??7777?J7!7J#?:^J7~^::7??YY:^7!7    //
//    ::~!!Y5J??JYYJ5GGJ#Y^^75~:!!!~^YJ:!P77Y57777755YYJJ7!!!?JJYYGGJGYJ!^7?7^^:~J7~!J5!^~7J7~^^!J7JJ^~~!!    //
//    ~^^~~Y5Y!!Y5YY5PPYBY~^75~^!!!^^J!:!G?JY?7~!!!JYYYYJ?7^^~~77YPP5G7!777!^:...~7777J~^~!??^^~?7~77^~~!!    //
//    ~!7^!YYY??5YJY5PPPB577?!!!7777!~!!7P?JJ???77~JYYYYJ77!!?7!!YPPPG?.:::...........J77??YY?Y????J5~!~~^    //
//    ::~Y7JJYJ5YJJJ5PPPG5!!B!7?J7??J7Y?7GGY7J?7??7Y5YYYJ?~^~YJ~^?PJPPY:......:.......5YY5555J?YJ??Y?~~~^^    //
//    !~7BY5555P55YYPGGGGB5?GYJ?JYY??5P5P#PY?JJJYY?5P5P55Y5J?YJ?77PYPGG?~~^~~!~~~!~~^JBG5Y5PP?5PPPY?J777!!    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@&&@@@@@&&&&&&&&&@@@@@@@@@@@@@@@@&###&@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@&~:^:[email protected]@@@@@@@Y::[email protected]@~::::......:~75&@@@@@@@@@@#: . :#@@@@@@@@@!.:::::::^^^^:[email protected]@Y:^:~&@@@@@@@    //
//    @@@@@@@&.   [email protected]@@@@@@G    [email protected]@^   :!77!!~:   [email protected]@@@@@@@&^     ^&@@@@@@@&~~~~~~~~~.    [email protected]@J   :&@@@@@@@    //
//    @@@@@@@@^   [email protected]@@@@@B.   [email protected]@@!   [email protected]@@@@@&5.   [email protected]@@@@@@!  .7   [email protected]@@@@@@@@@@@@@@@5.  :[email protected]@@Y   ^@@@@@@@@    //
//    @@@@@@@@~   [email protected]@@@@G:  [email protected]@@@7   [email protected]@@@@@@@7   [email protected]@@@@@?   [email protected]   [email protected]@@@@@@@@@@@@&7   7&@@@@P   ^@@@@@@@@    //
//    @@@@@@@@!   JGP5J~   7#@@@@@?   [email protected]@@@@@@&~   [email protected]@@@@Y   [email protected]@@~   [email protected]@@@@@@@@@@B^  [email protected]@@@@@G   [email protected]@@@@@@@    //
//    @@@@@@@@7          [email protected]@@@@@@?   ?55PP55?:   [email protected]@@@@P   [email protected]@@@#:   [email protected]@@@@@@@@5.  ^[email protected]@@@@@@G   [email protected]@@@@@@@    //
//    @@@@@@@@!   ?GGG7   !&@@@@@@?             ?#@@@@@#.   5#####Y   :#@@@@@@&7   7&@@@@@@@@G   [email protected]@@@@@@@    //
//    @@@@@@@@~   [email protected]@@@?   ~#@@@@@!   ?BBBBG^   [email protected]@@@@@~               ^&@@@@B^  [email protected]@@@@@@@@@P   ^@@@@@@@@    //
//    @@@@@@@@^   [email protected]@@@@J   :[email protected]@@@~   [email protected]@@@@#:   [email protected]@@@?   :777777777^   [email protected]@@Y   ^#@@@@@@@@@@@Y   :@@@@@@@@    //
//    @@@@@@@&:   [email protected]@@@@@5.   7#@@^   [email protected]@@@@@B.   [email protected]@5   :#@@@@@@@@@&:   [email protected]    ~7!!!!~~^:[email protected]@J   .&@@@@@@@    //
//    @@@@@@@&^.:[email protected]@@@@@@B~...^#@~.:[email protected]@@@@@@G:.:.J#:[email protected]@@@@@@@@@@G:::.G5............. [email protected]@J.:.^&@@@@@@@    //
//    @@@@@@@@&&&&@@@@@@@@@@&&&&@@&&&&&@@@@@@@@&&&&&&&&&&@@@@@@@@@@@@@&&&&&@&&&&&&&&&&&###@@@&&&&&@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    &&&#&&&&###&&&&&&&@&&&&&&&&&&&&&&&&&############&#&&@&&&#&###&@&&###&###&&&#####&&&&&&&&&&&&&&&#&&&@    //
//    5Y7^JGYJ!!~!?JGGGGBP555J7?5P55555PGB55Y?J!~!7J77Y??Y55557?!?!5PYY?7!!~!7JJJ!~^~7YG5YP55PPPP5P5Y!!77?    //
//    !~:.JGJ7!75J?7PGGPBG555JJJ??5YY?5PPB5PP55Y55YJ5YGP?JJ?J?777?JJJJP??55PPPPPPPYY??PPG5GPYJJYYJ5PJ~~!~!    //
//    ^^^^7J7~:^?!~^!??YYP5PPGY777J!555JPPJYJYYJ7JJ?JYY7JYJYY5YJYPGYYY5GJ55YP5PPPP5575#YPYGJJYY55YJPY^~~~!    //
//    ^^^^.  .:..::.     .?GPP55?!JY555PY^~~^^:......  .?YJJ5J?7JYP555PBBPY??Y5YY77?5BB55YGYJYYP5YJGJ~~~!!    //
//    ^:::.  ::.....       :!7P5PPPP5PJ! .::.   . .    .?YYY55YYYYPP5PGGGBP55?JJ?PGGP5PBGGPP5PPGGPPP?~~~7J    //
//    ^^^^.  ...          .:~!?YPP5JYJ~   ....   ..    .?YYY55555Y5PPPGBGPJJ5777?YYJ5PPBG555Y5JJY555?~~~7?    //
//    ::::. . .        .^7J?J?7J55J77??7!^  ..         .?YYYY5PP55Y5PGGPJ??7!777??7??5PBG555Y555PG5YJ~~~~!    //
//    :^^:.          .!?J?7777!?JJJ7?7777J?. ...  ..    ?YYYY5P555YPGPJ777777777777?JJYPG555YY5J7P5JJ~~~!?    //
//    ^^:^^^:7:!7.:!?J????7777777????77?77??:^^:::::::::~JYYYYYY5YPGJ?7?!!??777!!!!77?JJ5P55JJY5YYYYJ!~!7!    //
//    ::::JP!B7J577YGP77?777!!!!7?7????7777J57?7777YGPG5^^::^^^75YG57??7!7?7777!!!!!77?JYGPJ?JY55YYYJ~~!7!    //
//    ~^^^JG??~!?PPPG57777?7!!!!77??????777??!7!^~?PGGGP~~^ .  ~YYGJ77J7!7777!7!!!!7!??JYPP~!YYYYYYY7^^^^^    //
//    JJJ!?Y7:.:^77!YJ777??77777777?????777?5YJ7?JJ?PPP5~PGJ7!7JJYB77?J?J?7?7!!!77!7!7?7JG5J?YYJJYYJ^~7!^~    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RAREKRAZI is ERC721Creator {
    constructor() ERC721Creator("RARE KRAZI", "RAREKRAZI") {}
}