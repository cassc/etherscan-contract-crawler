// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DREAMING NIGHTMARES Whispers
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@#@@@@@@@@@@&&@#BGPB#&@@@@@@@@@@@@@@@@@@#B&@@@@@@@@@@@@@@@@@@@@@@@#&&&&&&&@@@@@@@@@@@&###&@@@@@@@@@@@@@@@@@@@@    //
//    @@@@##@@@@&[email protected]@@@&&&@@@P#@@@BP#G5&@@@@##&&#[email protected]@@@#[email protected]@@&#BGGPY7555PPP#@@@@@@@@@#[email protected]@@@@@@&[email protected]@@@@@@@@@    //
//    @@@@[email protected]@@@#[email protected]@[email protected]&Y&@@@5G&PY&@@@&##B#BBBB####JP&&&&&&#[email protected]@B5YG&@@@&BB###[email protected]#@@@@@@@@@@@@[email protected]@@@@@@@@@@@@[email protected]@@@@@@@@@    //
//    @&&&JB&&&#[email protected]&@@[email protected]@@&#Y55G&@@@@@#B#@@@@@@@&55&#[email protected]@@@55BYYB&&&@@@@@@@@&[email protected]&&@BYPPG&@@&[email protected]@@&&@@@&[email protected]@@@[email protected]    //
//    @&[email protected]@&GY#@5P&&####&@&&&&@&[email protected]@@@@@@5Y#[email protected]@G77?B#5JJJ#@@@@@@@#?&B7B5G&J5&@@@@@[email protected]@#55G5&##&B&&P?#&&&@@@@[email protected]    //
//    @@@&J#@@@#J&@#PPPG&@@#PGGB&&&&&#########@@@@@@GJP?J57?P#?G#555!?J5B&@@@@@@[email protected]!BB!PG&@@@@[email protected]#?G&#[email protected]@[email protected]@    //
//    @@@BY&@@@[email protected]@@@@@@@@@@@@@@&#&&&##&@&###&@@@@@@##G#&&[email protected]&@&YP&#BBB&@@@@@@5B&Y#&[email protected]@@#?&@PY&[email protected]#7Y^Y57PJJ&[email protected]    //
//    @@@[email protected]@@@&&&&&&&&####B&@@&#@@@@&&&&&&##B&@@@@@@@@@@@@&@@&@@@&[email protected]@@@@@@@@@@@&@@&@@@&####&@@@[email protected]&GY5P#&5&&[email protected]&BY55#P!PG    //
//    @@@@@&&##&&&&&&&####&&@@@#&@@@@&####&&#Y5###&#####&@@@@@&BGGGGGBPPPPG&&&&@@@@@@@@@@@@@@@@@BYP5P&@@@@@@@#&@@&&&@@@@@@55B#    //
//    @@@@@@@@@@###&&&@@@@@@@@@[email protected]@@@#B##&&BGBBBGB#GG5B&##&@&#GJ7?!~J5B5???JBB#####&&@@@@@@@@@@@@@&&&@&&&&B#@@@&&&&&@&&&&@@@@@@    //
//    @@@@@@@@@@&##B#@@@@@@@@@@B&&@BGB&&#BB&&&&B##PJJJB&&##G7J~.77?PB#BGGGBBBBBG5JJJYPB#&&@@@@@@@@@@#5G5GP#@@[email protected]@@@@@    //
//    @@@@@@@@@&#&&&@@@@@@@@@@&BBPB#&@&&&&&BB&&GYJJ?!~!YPBG?~Y^.75G5BBBB########BGP5YJJJJY5PB#&&@@@@[email protected]@B55BGB#BBG&@@@#&@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@&BG#@@&#GGG#&#&&&B5!^!77~~?BGG5Y7^~J5YPB#&##B##&#####BBBGP55YJJJY5PG#&&&&@[email protected]@@GPGB#@###PBG#&[email protected]    //
//    @@@@@@@@@@@@@@@@@@@@@&#B#B#@@@#57~!JP#&@&##GJ?JP7!JGGBGP5??5GGBB#BPJ??5#&&####&&&&##BBGP5YYYY5PG#&&&@@@@@@[email protected]#[email protected]#B#[email protected]    //
//    @@@@@@@@@@@@@@@@@@&#BB&@@B&@@&G?^. ^?G#&&&&#GPPPJ5PP55PGBGGBBP#BP7~!!?G&@@@@@&&&&&@@@@&&#BGPP5555PGB#&@@##JB&P#JG5YG&5#@    //
//    @@@@@@@@@@@@@@@@&##&@&&&&[email protected]@@&P7~.  ~PBB##&####GBBPJYY5PGGBBBBBBPJJY5PBB#&&&@@@@@&&&&&@@@&&#BBGPPPP5G#&#PP5##&@5##GBGP#@    //
//    @@@@@@@@@@@@@&#&@@@&#&&@#[email protected]@@&PJ!: .!5PGBBBPPP5YY5555Y5PGGGGGGGY7~^~!!77?JY5PPG#&&@@&BBBBBBBGGGBB####&&&&&@@@@@B&@@@&#&@    //
//    @@@@@@@@@@@&#&@@@##&@@@@&P&@@&BY~:.:75PPGB5~?YYP5PBBBGP5J77~~~~^:^^!!~~~~!!7777?J5GBBGGBBBBBB########&&&&@@@&@@@@@#@@@@@    //
//    @@@@@@@@@@#&@@&&&&@@@@@@@P#@@@B5!:.!JJ5PGGJPBP55G&&BBGBBGGPY?~^:.^~!7!~!7?777777JJYGBBB#####&##&&&#&&&&#G###GB##&&5&&@@@    //
//    @@@@@@@@@B&@&##&@@@@@@@&#B5#@@&BJ!!YJ?Y5PP5GGG##BG5PPB####&&BY?!!!?7?J???7?JYY5JJY5GB#&&&&&&&&&&&&&###@&&&#####BBBG#G&@@    //
//    @@@@@@@@&G&#&@@@@@@@@@#B&@BPB&@@#GGB5JY55PPGBBB#&#P#&&####&#BBGGGBPYJ7^^^!JYYJ?7?J5G#&@@@@&##&&&&&#&B#BGB#&&GBBB#BGG&@@@    //
//    @@@@@@@@&P&@@@@@@@@&#[email protected]@@@&BG#&@@&&#GGBB###B&@@@@&G#@@&##&&G5J??Y5J7?77JYY????JYP#@@@@@&###&&&&&&&&&####&&&B#B##GB&@@@@    //
//    @@@@@@@@@P#@@@@@@&&#B#@@@@@@@@&###&######&&&&#######BB&@@#B&#GYJ7?JPGGP5YYJJJJYP#@@@@@@@&####&&@@@BGBBBB&@#GBGBBBGGG##@@    //
//    @@@@@@@@@#GBBB#&&&######&@@@@&B#@@@@&&&&&&&@#&&&&&&&&&BB&&#B##BG5JJG#BG5555J7J#@@@@@&BG5J77?5&@@&#GB#&@&@@@@&##&####&&@@    //
//    @@@@@@@@@@&####&@@@@#BPBGGB&&@&&@&&&###&&@@@&B&@@@@@@@@&#B#BGB##BPP&&#BGGP5J7Y&&#BGY7~^:...^[email protected]@&GBPGB#[email protected]@#BBG#[email protected]@@@    //
//    @@@@@@@@@@@@@@@@@@@@@#GGPPGBB&&##&&&@@@@@@@@@B#@@@@@@@@@@@&#BB#&#&@@@&&&#PY7J55??77777!~!~^^!5#@@&&#&&&#&&&@@&#BG&B#@&&&    //
//    @@@@@@@@@@@@@@@@@@@@@@&[email protected]@@@&@@##@@@@@@@&G&@@@@@@@@@@@@#BB#&@@@@@@@#GPJ7~^~?Y5YJ?!^?7~^7YP&@&@&&@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@&####[email protected]@@@@@@@BGGBGBGPPG#@5P##@@@@@@B#@@@@@@@@@@@@BB&#B#&@@@@@@&#GJJY5GGPPPY7^7?~~!5Y&&&BB&&&&@@@@&@@@@@@@@@@@    //
//    @@&#GPPPJJGGGPJJ&@@@@@@@@[email protected]@@@@@&G&@@@@@@@@&##G#&#&#G##&@@@&#####BGP5PGY?!?J!~~YP##BP##PGG&@@&G&&@@&B###&B    //
//    @@&B#&@@Y5GP5PB&@@@@@@@@@5?5PPBB##&G7&&@&&&&&&PGB#&GP5PGJJY?Y&BJP5B&&&##BBB##BBBGGGBBP5YJY7~!YB&&&G##GBB&&@&G&&BB###B#&#    //
//    @@@@@@@&!75G&@@@@&&@@@@@@&#[email protected]@[email protected]&@@@@#GPPGGGGGPYYPGBBBGJJ?!~5#@@@&&BBBB##@#G#[email protected]@GPG&@@    //
//    @@@@@@@&7GBPJ&#[email protected]@@@@@&#BPYJYBB?#5J#YYP55#JP!??5J!YGJB#BP&[email protected]@@@@@#GGGGGPPY7^^~7?YYJ77?7~YB&@@@@@@@@@@@&#&#5#@#GB&@@    //
//    @@@@@@@G7GPYPP7JPPG&@@&BPP5PGB#[email protected]#@&B#&@@#&GBBY5#@@#GGBG#@@@@@@@&#&@@@&BBY7^::.:[email protected]@&@@@@@@@@@@@@#&@@@&&@@    //
//    @@@&#G5JJG#&@#YPPG#@@@@##&@@@@@&##BP#@@@@@@@@@@@BYP#@@@@@@@@#[email protected]@@@@&GB&@@@@#G#B57~:..^[email protected]&@@&@@&#&@@@@@@@@@@@@    //
//    @#P5PB#&@@@@@@@&##@@@@@#[email protected]@@@#@@B&#BG#@@@@@@@&@@#[email protected]@@@@@@@@@&G&@@@#G&&&@@@&P#&#P7~..:~!!!JYJ!~??J#[email protected]@#@BB&&&&&&@@@@@@&&    //
//    @&#@@@@&BB##B&@&[email protected]@@@&[email protected]&#PP&@GP5GYB#&@@@@@B&@&5&@@@@@@@@@&G#@@&B&@@&@@@#B&&#P!::^^[email protected]&[email protected]&@&PGGG&&BBBBG#    //
//    @@@@@@&BP5J?PYY5?#@@@&Y5BGBBJB&&5J#[email protected]@@[email protected]@@@@@@@@@####@#&@@@&&@@##&&&B?::!!!7~7Y55J~~777GGB&@&GG#&GGB#@@&&&&@@    //
//    @@@@@@P55G#[email protected]@@@@P5GPB&[email protected]@#[email protected]&PPP#@@@[email protected]&#@##@@##&&BB#&&@@@@@@&&@@&#5!^??JJ77Y5YJ~^~!?Y&@@@@#P&@@@&&@@@@@@@@    //
//    @@@@@@@&@B&@@[email protected]&@@@@@&@@&&@@@@@#&&&&&@@@@@@@@@@@@&&@&&@#BBG55PPYJGPP#&&&&&&&#@@&GJ~JJY5??JY?7~:^^[email protected]@@@@G&@@@@@@@@@@@@@    //
//    @@@@@@@@@PB&&[email protected]@&BG&#&#&&&@@@@@@#@@@&&&@@@@@@@@@@@@@#G5?~^:^^~7YPPB######B#&&&&@&PYYYPP5YYJ7!~::~!75#@@@@&@@&&#&&&&##&@@    //
//    @@@@@@@@@5B##5#GPB5B#&&#&&&&@@@@#@@@@@@&&@@@@@@@@@#PY?!^^^^^^~?5GB#&&&&B#@@@@@&&&#G55PPGGPJ?7!:.:~!?P&@@@@@@G#####GB#&@@    //
//    @@@@@@@@@G&@@B&#@@#&@&@@@@@&#@##&@@@@@@@@&&@@@&#GYJJ?7??7~^^7J5GGB###&&&#&@@@@@@&###BGBBBBGPYJ~..^[email protected]@@@@@P#@&@BB&@&&#    //
//    @@@@@@&@&@@@@@@@@@@@@&[email protected]@@&##B#@@@@@@@@@@@&#G5?!~7JJ7!7JJY5PGBB#&&@@@@@@@&#&@@@@@@&&@&&####BG5?. .~~!P&@@@@&P&@B##[email protected]    //
//    @@@@@BB#[email protected]&&@@B&@&&@@&[email protected]@@#[email protected]@&&&&&&&&##P?!~!7YPPPGPPGGBBGPPGB#&@@@@@@@@@@#&@@@@@@@&@@@&&&&#PY^ .^!^[email protected]@@@&P&&###5#BG##    //
//    @@@@@PBGB#[email protected]@[email protected]@G#@@&[email protected]@&G#&#GY?775&&&&#BP5PGGBBB##&&##&5?PB##BB&@@@@@@@@@&B&@@@@@@&&@@@&&##B5^ .^!^7Y&@@@@GB#@&&P#@&&&    //
//    @@&##[email protected]&[email protected]@P&&BG#@&55BG5??7?PB######BBBGG#&&@@&#&&Y7B&@@@@@@@@#[email protected]@@@@@B&@@@@&&@&@@@&&&##J...^!^~7P#@@@@@@&&&#&@@@@    //
//    @@@@&G&G&@&#@#P#B5#G#5&#Y!!PP!^^^!?5PPPGB####G#&&&&&&@@#!G&&&&&5G&@#[email protected]&@@@&BP#@@&5#@&#BGG#&&#Y:.::^.^!7?BGY5YYJJ5#@@&&@    //
//    @@@@@@@@@@@@@#[email protected]#PG&#5&P7!7PY~7J5YPGB#&&&##&B&@@@@@@@@@G7&@@@@&~5&#J7#[email protected]&[email protected]&&JJ5G#&@@&P!...^^77P~Y57GGPP55PPPPG&    //
//    @@@@@&###@@@@@@@@#@@##@PJJYPB##&&&@@&&&&@@&B&@@@@@@@@@@57&@@@&G^?YY~YJ5YJ&[email protected]&P55G&@@@@#?: ^7^775~Y?755G#PP#&&@@@    //
//    @@@@#PB##G#@@@@@@@@&#@&GGB#&&&@@@&&&&@@@@#B&@@@@@@@@@@@P7&@@@&P^P#5^?5GY7&B!#5?#[email protected]@@&[email protected]@@@&P^ !Y^?775B?G&#BG7YPG&@@@    //
//    @@@@5#@@@@&@@@@@@@@#&@[email protected]@@@@@@@&&@@@@@&##@@@@@@@@@@@@@&?P&&GJG7#@Y7G&&G7&#J&G?&#75&BP5P#&&@@@@#?.~PY7!P&BJ&@&&B?#@@@@@@    //
//    @@@&Y&@@@@@@@@@@@@@[email protected]@G&@@@@@@@&@@@@@@##&@@@@@@@@@@@@@@@&PYY5B##@@##@@@&[email protected]@&@&#&&P55??J55PGB#&@&B!:!!?B&@[email protected]@@@[email protected]@@@@@@    //
//    @@@@Y&@@@@@@@&&&&@@[email protected]#[email protected]@@@@@@&@@@@@##&@@@@@@@@@@@@@@@@@@@@@@@@&&&#####BBBBGP5J7!^::...:^~!?J5PBB57!7P&&@P#@@@@[email protected]@@@@@@    //
//    @@@@[email protected]@@@@BGGBBBGG#@BB&&@@@@@@@@#&#&&BBB#&@@@@@@@@@@@@@@@@@@@@&&######BBGPJ7~^:::::::^~~!7?7?YY5J?7?PGGGGGBB###&@@@@@@&    //
//    &#[email protected]@@@GP&@B#@#5#GP&@@@@#@@@@@5B&@#5B#&@@@@@@@@@@@@@@@&&@@@@@@@&&##G5J?!!!!~~~~~~!!777J5PPB##[email protected]@@@@@&&    //
//    @@@@[email protected]@@@[email protected]@&&#PB&[email protected]@@@@[email protected]@@&J#@@@&#[email protected]@@@@@@@@@@&####BB###BBGP5Y?!!!!!!777??77?JJJJY5GGGGBBGGB######&&&&@@@@@@@&&&    //
//    @@@@@@@@@@&GGBBGG#@&BPG#&@@&GB#[email protected]@@&@@&B5&@@@@@@@@@#B&BJ~~75PPP55P5YYYY55PGGB##&G55PPPGGBB#&&&&@@@@@@@@@@@@@@@@@@@@&&&    //
//    @@@@@@@@@@@@@&&@@@@&#@&&@@@@@&BB&@@@&BGGGB&@@@@@@@@@#GGJ~.^?5PPGBBB#BB#####&&&&&&&&&&###[email protected]@@@@@@@@@@@@@@@@@@@@@@@@&&    //
//    @@@@@@@@@@@@@@@@@@@@##@@@@@@@&&@@@@@@@@@@@@@@@@@@@&#GJ^:~J5GBB#&&&#######&&&&##BBGGGGGGGBB##@@@@@@@@@@@@@@@@@@@@@@@@@&&&    //
//    @@@@@@@@@@@@@@@@@@@@@###&&&&@@@@@@@@@@@@@@@@@@@@&BG5!:~?5B####B##&&&@@@@@@@&####&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&PYJJ5!..^?P###&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BY^^!!~^~7YPB#&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@@@@@@&&&    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@&5~^~^:^75PB&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@@@@@@@@&&&&&@@@@@@@&#    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DNGW is ERC721Creator {
    constructor() ERC721Creator("DREAMING NIGHTMARES Whispers", "DNGW") {}
}