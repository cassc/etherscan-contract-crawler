// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Back on it
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    GB#BBBBB#####GJ7~:.......!7........^[email protected]@B!.5P!7Y5?75B&B5:.....................:^JGBG#@#GGPPPPPGBGB#    //
//    ##BBBB###GY7!^:........^[email protected] .5GJ^ 7BGP!~P&?.!77~::G57^:...................:[email protected]&&@@@@&&&&#GPPGGGG    //
//    #BB###PY?~...........:^?P5&&^ 7PY#?~5PP7 .^^.  :~?Y~ ..................:^77GB#BGJ7^[email protected]@&&&@#GPPGBB5PG    //
//    #BGYJJ~.............. !PP5G&G..PY^?PY!P7 .....75PPP~......~JYY7..:^[email protected]&[email protected]&&&@@@B5GB    //
//    5?!^:......^~7Y!...  .JPY75P#7 :^~P5::5Y.....JPPJJPJ:...:?P575J^~7Y5B5J!~^[email protected]@@@@@@@&&@@    //
//    ::.. ^7~..:5J?P5~.~Y7~PP7^!5PY^ :5Y^ .YP^  .JP5!.7PY:..!5PJ::55PB&B5#GJ5P5GGGBBBG#Y7Y77Y&@@@@@@@@@@@    //
//    ..:!P&@5..~PJ.!5P?P#7?PY::.^5P5!7P~ ..?P? :YP7. .YP!.:?PYJ?:[email protected]@B?&5Y55P5B#[email protected]@@@@@@@@@@@    //
//    .7#@&P!...~PY?~^JPPGYY5^... !PPP5Y....?PY^YP7. .^P5~75P?JY?:JPG#&@B?JJY5PP!GBP5YJ?~?PB:[email protected]@@@@@@@@@@@    //
//    .^P#5. ...!P55Y?^!5P5PY......7PPP?.:!~!PP55!  .:7P5JPJ~J55J:Y5#@@@575PJ55!:PGP5YG!!##Y:[email protected]@@@@@@@@@@@    //
//    .~55P5^ ..7PP?7~:.:?PPY:......~Y5^^7!!.Y5?^:!?J7?PPJ~^[email protected]#YYPJ~7P? [email protected]!PY!75&@@@@@@@@@@@    //
//    .Y5^~??!: ?PP?::....7PP7...:~~!P!..^!^:^7!YP#&&?7PY7JJPPGB#5PJJYJ5Y7:~55:^PGGB#&&&GJ7~77#@@@@@@@@@@@    //
//    !P7   ~YY?YP5Y#^....^7!~!..~7!5Y!^..:!?5B&&&&&&#GB#BGP#&&@#PP~^JPY7Y^YP!^G##BPY5#@@&[email protected]@@@@@@@@@@    //
//    JP^ ...~?Y5P5Y7..:..~!J5^...:?5^^~7YG&@@@&&&&&&&&&&&PYBGGBGPY!YJYGGGPPY:G&[email protected]@&#&?^GB#&@@@@@@@@    //
//    J5:.... :^?PYJ^..55:!?BJ!:...??5B#&@@&&&&&&#&&&&&&&@G5&#G55PP5J~YGBGPP7^Y7?55??5PPJ?5&B.JJ?7JB&@@@@@    //
//    JY....... !P7....:PGJG7~^^^75B#@@&&&&&&&&&&&&&&&&&&@PP&@&&BB###BGG5PP57~?YP!.~55?YB&@@G~5&&#[email protected]@@@@    //
//    YP: ......:J~......5&?:7PB&@@@@&&&&&&&&&&&&&&&&&&&&&##&&&&@@&&&&&G:~Y5YPGB? !5P#@@@@@5^5G#@@@@@@@&&&    //
//    !5^ ..............~?JGGBBBBB######&&&&&&&&&&&&&&&&&&&&&&@@&&&&&&&&7 [email protected]&?.7PP#@@&&@[email protected]@@#&&&&&    //
//    .^:............:^^^~~^:::::~J55PG##B&@&&&&&&&&&&&&&&&&55P#@&&&&&&@#^ :G#! 7PP#@@@&@B!#@@@[email protected]@&&&&&&    //
//    . .........:^^^^:.   .:^^::. ..:^7PGG#@&&&&&&&&&&&&&&5YP5Y5#@&&&&&&J .~:[email protected]@@&&&[email protected]&&&@&[email protected]&&&&&&    //
//    ........^!YJ!^.  :75GBBBGGP5Y: :^ ^G#PBBBGBBBBBBBB&@@#G5Y55Y5B&&&&&J . [email protected]@&#B&@@&&&&&&5&&&&&&&    //
//    .... ^?P##?^.. .J#@&&&BGBB&Y#5 :~. [email protected]&&&&&GPBGGGPPPJJYY?G&&&@5 [email protected]@&##&&[email protected]&#&@@&&&&&&    //
//    ... :[email protected]@B!:.. :G&&##BBGG#&G7#G.^P. !&&&&#&&&&&&&#J^^:.....:!5PB&&&&7 [email protected]@&P5B&@@#P5P&@@&&&&&&&&&&    //
//    J:  :[email protected]~^:...5&&#GPPY5B&@[email protected] ~5. ?&&&B&&&&&&&P::7~. ..:.. .!G#&&#^ [email protected]@@@#5PB#G55B&@@@&&@&&&&##&    //
//    &7 . :Y?Y^.. [email protected]#?B&^.J! ^P&&B#&&&&&&#::?^ .!?7!~7.. !B##B:.:[email protected]@@@@@&BB55P#@@@@@&&@@@##&&&    //
//    &G: ...YB?. [email protected]#7 :: [email protected]&G&&&&&&&J.!^ ^5Y7?7~J:..:5G&B.. ^&@@@@@@#GGPB&&@@@@@&&@@@&&&&&    //
//    &@P. ..!BB?~ . ~5GGPGPPGPJJ~   ^5#Y#&&G&&&&&##!.: .JJ?5J7!^.. ^#&@P . [email protected]&&@@#GB#PGBB#G#@@@&&@@@@&&&&    //
//    &&@~ ..:?#5J!.  .^7JY5YJ!:. .~?#@BYB&&G&&&&#&&~ ..:^^~?!::... Y&&@?  [email protected]&&&#GG#BP&@G5#&G#@@@&@@@&&&&&    //
//    &&#~ ..!GBGJJ7^..      ..^7YB&&&&J!#@&G&&&&&&@Y .:^~^^~~::.. 7&&@Y. ~&@@#PG#&PG&@&PP&@G#@@@&@@@&&&&&    //
//    B&B:..~?PP5GBGG555Y!JJ5PB&@@&&&&?  7B&#&&B#&&&&7  .^!!7~...:?GG57. ^B&&BP#@&PB&#BB5#&B&@&#[email protected]@@&&&&&    //
//    ^!J7..!JJ:.:[email protected]&&&&&&&&@P .. [email protected]&&&##&&&&Y^.     ...:7~~: .~5GP5G&@@P5GBB#@GPB##BGGB&@@@&&&&&    //
//    :::^. :?GP^   ..^~..!&&&&&&&&&&! ... :[email protected]&&&&&&&&@BJ:.:^..:~!^.  :?^:7BB&@@@##&@5^7PBGBBB#&@@@@@&&&&&    //
//    ^::^:. ~YBG!:  .~!7^.J&&&&&&&&#: .::. :[email protected]&&&&&&G5??^.:~^^~!^..:~55.  7&@@@@@@@#:  J#PPPB&#@@@@@@&&&&    //
//    ^^^^!^ .~75B5^^.  7~.^5#&&&&&@5 . ^7 . :[email protected]&&#Y?^^^::?PY~..  :7YGBB^ . [email protected]@@@@@@Y . JGPPP5!^7&@@@@@&&&    //
//    ^^~^^^.. .JPJ777~:...:!G&&&&@B~ . :Y::. ^[email protected]#5:  :?PPPJ7:...:Y5G#B&! .. [email protected]@@@@@? . 7P5P5~  .5&@@@@@&&    //
//    ^^^^^^: . :P55G5YJ!...:G##&&&P^ ...Y?^:. ^57~^ .:GB5^.  .....^YBB&Y :.. [email protected]@@@5....!JJ~... ~&@@@@&@&&    //
//    ::^^!YP~ . .^:!PGGJ...?5B&#5?Y^ ...:^.... .7P! ..7!. .~7. ^Y7:.^?BG ^!.. YG5!....:~..:^..:[email protected]@#[email protected]@&&&    //
//    ::~5B##J .. ....?BG. .G&5PBP~G?^. .:^:..   Y&! ...  :?GB7 .!BB5!..~..5?.  .:7Y~  .:!?!..:[email protected]&?:^&@@@&    //
//    ::!PG#B7~...  ...~!. ^[email protected]?:JGPBGGP5!B#BGPY7Y&@7 . .7J7GGBBJ. :?#&BJ^.^B&PYJP#5^  :7?~..^[email protected] [email protected]@@&    //
//    :!7YBBPP?^.:::.. . . ~#&B~?G#B&&&&5#GG&@&[email protected]@&##BBBP7: .7P&&B&@@@@@@@P7JJ!:.^7J5YJYY:...#@&@&    //
//    ~7^Y#PBG?:::~7~:::.. :[email protected]@BJG&&&@@@@&#BBBPJ7?^ [email protected]##BGGG5!  ^JPB#&&&&&&@@@7  .??~:    .. :&@@@@    //
//    7^^JPGBP5::::?J^5Y~ ..^77?~7??JJJJYJJ??7!^^~:.....^75G&5YJ????~.    .!#@&&&&&&&#?^^:::~?P5P7  [email protected]&#@@    //
//    77:^5PBG5~~^:~!~GP~ ..                      ....?PB&@@P7     .^7??7JG#&@@@&@@@@@@@&BGPGGGPJ. [email protected]#G&@    //
//    ??7^?G##5:!Y5??5BY^...:?J7..~!: ~?J5~ :~:::::. :G&@&&&&#Y~.  .:7?JY5G#@&B#&#&&PY?!^:.......:7#@@&B&@    //
//    [email protected]&&&&&5 ..:[email protected]&^ [email protected]! [email protected]&@P..::!7JY: ~&&&&&&&&@&BY?^:..   .:7PPG#P?^   .:^[email protected]@@@#&@    //
//    55YGBBB#B#&&&&&&&@[email protected]&~ [email protected]&&&~ ^P##&?  ?&###&&&&&&@@@BPB5?J~   ^:?5^. .75G5JJ55B&#PPP#@@@&#&    //
//    P5PBBGB&#&&&&&&&&&B....7&@! ~&B: [email protected]&&J [email protected]##&J~ 7###&&&&&&&&##BPBGG7:...!7GJ^: !#&#5JJY5B&[email protected]@@@&&    //
//    5PGGBPB&&&&&&&&&&&&~ . J&@7 [email protected]~ [email protected]@G ^&@@@P? :[email protected]@@&&&&&&&GBBBPY~~^~..PPPPJ: !###PPPPYB&GPPP#@@@@&&    //
//    PGBBBBB#&&&&&&&&&&@? . ?BB7  7&7  J&#G:.YYJJ~: .P&###&&&&&P5BB57:!YY7 .^[email protected]&J. !BBB5YYYYPG5YYYB##&@@&    //
//    PGBBBBB#&&&&&&&&&&@G^   ... ....  .:.. ...^^7JJPBBGBBBBBBY!5G!:?PB##? .~7B&J  !GBB55555G#P55PBGPPG&&    //
//    5GBBBBBGB&&&&&&&&&&&GJ?77?!^...:~7??7JJJ5PGGB##BPBBBBBBG5!!?:^5P####J. J#PP5. !P#&GP5P55#PPPG##BG55&    //
//    5GBBBBY~?PG#&&&&#GGGB&&&&P5GPGG#&&BBGY&####BBG5JYBBGP5JJ5Y^:?BBG#B##Y. [email protected]@@G. ^GPGB5?55~PP?5G#BB5YY&    //
//    BBBBB?^:7YPB###PPB#GY7!~~:~75#@@@#BBP7JJ??777!.^5PYYJJJY7:^5BBBGB#BY?. [email protected]&@5...~B#[email protected]    //
//    BB#G7:^~J5GPYYYPBJ~~7YGBBBGJ~:!PBPP5Y55PPGGP57?^:^!!~:.^.:?BBBGG#PYG5  [email protected]&@Y. ?7^G&B5YYJ~JYYY5PY?JY&    //
//    BB5~:^^[email protected]@@@GY77G&&######&&&###BY~.!PY~:?JPBB#G5J5##7  [email protected]@&! .J#!^G&GPPP77P55G&GJ??5    //
//    B?^::^YB5!5##?^YP5GG#@@@&P?~:JGGGGY?YG&&&@@@@&&B#BJ.7&#77&&#&#PYG##B:  [email protected]@B:..5##!:G#PPP5^JPPG##P?77    //
//    !:^^^Y#G??&B~?#@&@@@&B57^~JG5J?J~JB#P?7?5PG#&#P?!?5J [email protected]~#@@&&##&##P.. [email protected]@5..^5##B^~#BPPPJ!?PPGB&G?~    //
//    :^^~5##PJPB~?BGGGPY7~^!?^G#BBBBB7?PPBBG5!~~^:^^^::^:.^[email protected]@@&@@&&&? . [email protected]&?. !5###5.?#GPPPB5?55PGBG7    //
//    :^75###G757:^^::::.::!77:~!!!!~!^^!~!7?Y!^?J?JY?~^::!.:?7B&#&&&&&&#^ [email protected]&!  !5####~:PG5Y5PBBPGGPGBB    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BOI is ERC1155Creator {
    constructor() ERC1155Creator() {}
}