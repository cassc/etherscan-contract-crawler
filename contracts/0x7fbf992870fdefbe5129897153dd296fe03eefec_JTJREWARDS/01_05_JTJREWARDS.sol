// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JTJ - REWARDS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                             .7?JJYYYJJ:                                                        //
//                                                                                                                                    ..       JP777?775&^                                                        //
//                                                                                              ..::^^^~~~~~~~~~^^::...      .:~!^:!JPPP!     .B~:::::!G^                                                         //
//                                                                                      .:^~!7?JYY55555555555555555555YJ???J5PP5JGY?!~:^Y7    !G::^::7G:                                                          //
//                                                                                 .^~7JY55555555555555555555555PGGPP5GG5P#~^^:::?Y::::::?J.  YJ:^::?P:                                                           //
//                                                                             :~7JY55555555555555555555PPGBBGG#P!~^::^5G5B?:::^:^P~::^^::~J! G!:::J5.                                                            //
//                                                                         .^7J5555555555555555555PP555B5J?!~^:GP::::^::7GPB~:^^^:?P:::::::^?YP^::YJ                                                              //
//                                                                      .~?Y55555555555PGGGGGBGGGPYPG55GJ::::::!B^:^^^^::^Y#5::^^::BG55J7~^::~~::^G:                                                              //
//                                                                    ^?Y5555PPGGGPB55BY!!~~^G?~^::^5G55B~:^^^::PJ:^^^:^~::7B!:^^^:?&PPGBBBY:::^^:57                                                              //
//                                                                 :7Y55555PBJ7!~^:GPYGJ:::::J?:::^::JG5GY:^^^^:~B~:^^::YP^:^^:^^^::BBY5555B!:^^^:7G                                                              //
//                                                             :~!!?JY5PP5YPP::::::PP5G5::^^:7Y:^^^^::!PPB~:^^^^:JG::^^:^#G!::^^^^^:[email protected]:::::^#J.                       .::                                  //
//                                                       .   ^?!^^:::::~75PPP::^^::PP5PG::^^:!P::^^^:::^J#5::^^^::GY::^^:7&G?:::::::^B&55555G7^!?5G&BY!.              .:~7JYYY?~                                  //
//                                                .:^~~!!JJ !Y^::::^^:::::?BG::^^^:5P55#^:^^:~G^:^^:75~::!?::^^^^:~#?:^^::5#G5^:~7YP#&#555555GGGGGP55PPPJY!   .:^~!7JY55PY7^.                                     //
//                                          .:^!!77!~~^^::Y?P^:^:!Y5557::::7#^:^^^:YG5P&!:^^:^G~:^^:^PBJ^::^^::::::?&!::::!&#PGPB#BGP555555555PPPPP5YPG##G7!777?JJJ?7~:.                                          //
//                                    .:^!777!!~^:::::::^::G?:^:^P5555G5::::5?:^^^:!5YJ?^:^^::P?:^^^:^PBP?^:::~7YPGB&P!?5G##G5555555Y555PPPP5Y?7!~~Y55J7!~!!777!~:.                                               //
//                                  ~Y77!~^^:::::::^::^^^^:57:^:!G55555#J:^:7B::^^^::^^^:^^^^:Y5:^^^^:^BGPP?JG##BGP55PGGGP5YY5555555PPYJ7!~^::~7^::^:^~7JY5P5^                                                    //
//                                  ^BY:::::::^~7J5G5^:^^^:JJ:^:^GP555YBG:::7&^:^^^:7PP5::^^^:7#^::::^^[email protected]#G555&G::^!?J5GBY^~7JYPPP55555Y~                                                   //
//                                    JG!^~7?YYJ7~::GP::^^:~G^:^:[email protected]:^:[email protected]~:^^^:!BYB!:::::^&?^!J5GBBG555YY55555PPPP55YJ7!~^[email protected]&PPGPPB&GYYPPPP55555555555!                                                  //
//                                     ~5J?!^.      .&J:^^^:7P^:::~YGGGJ^::!&#?:^::::GPPP^!?YPB&BGGGP555555PPGGGG5B?~~^:::::^~!?&G555PP555G#BPP55555555555555555!                                                 //
//                                         .^:       PB::^^^:?B7:::::^::::?&#5P:::^!?B#5BBBBGPP555Y5PPG555GYJ7!^YPPJ:::!?JYPGPPP555555555555555555555555555555555~         .^!!.                                  //
//                                   .:~!777!7!.    !&5::^^^:7&BGJ!~^^^!JG&G55GYYG###BP5555555PPGBGP5JJB55B^::::~G5G^:^PP5YJPB555PP555555555555555555555555555555Y^ :^!J5GB##@&:                                  //
//                                   7G!^^::::~??7?JGY^:^^::^BBY5GBBGGBBBG55555PPP555555PPP5YJ?7!J&~:::PPYB5::^^:YPPJ::^JY5PGGPP5YP&55555555555555555555555555PGB##B##BG5J7~5&^                                   //
//                                    !57^:::^::^~~~^::::::7B#55555555555555555555PP55Y?7!~^::::::PG:::!BPPY::^^:~B5G^:^5YJ7!~^::::GB5555555555555555555555P#GGPYJ7!~^^::::J#^                                    //
//                                     :J5J!^::::::::::^!JG#G555555555555555P55YJ?!~^::::::::::^~!?#~:^:~7??^:^^^:YGPY:::::::^!7JY5GG55555555PGGBB#B5555555&J^:::::^^^^^^:J#^                                     //
//                                       .!Y55YJ?77?JYPB#BP5Y5555PPPPPGG555G&!:::::::::^^^:^7J5PPPG5::^::GPGJ:::::^#PB!~7JYPGGGGPP55555PGBBBGP5Y?77&G55555P#~^^^^^^^^^^^:?#^                                      //
//                                          .:!7?5BBGGP555PPPPP5YJ?!~^~##555&#!::::^~!~:^^:^BG55555G!::::?B5B7!?YPG#G5GGGGP55555555555GB7!~^^::::::P#Y5555BP:^^^^^^^^^^^7&~                                       //
//                                               !555PP55YJ7!~^::^~!7?JG&[email protected]&JJY5PPG#~:^^:!#555555P^:[email protected]^:^^^^^^^^^7&55555#?^^^^^^^^^^^!&7                                        //
//                                              .P###GGP5J^::!YPPGGGGPP555555PBGPP555YBB^::::?#55555PPPB#BG55555YYYY555PPGGBB########BG#5^::^^^^^^^^GG5555#~^^^^^^^^^^~#J                                         //
//                                            .:~5P5J?7!^^^^^~7JYPB&#P55555555555555555#P:^~7J#P55555555Y5555555PPGB###BGP5YYJ?????JY5PG##GJ~:^^^^^^?#555GP^^^^^^^^~~~B5                                          //
//                                      .:~!7???7!!!77?JYY55PPPPP55555555Y5B555555555555#GGGGP555555PGBBP5PGBB#BGPYJ7!~^^::::::::::::::^^!JG#P~^^^^^^GP55BJ^~~~~~~~~~PB                                           //
//                                :^7?JYYYJJ?7!!!5PPPP555555555PP55YJ?!~^^^[email protected]@#BPY?!~^:::^^^^^^^^^^^^^^^^^^^^^^^^!G&7^^^^^?B55#7~~~~~~~~~Y&:                                           //
//                           :!?Y555Y?!~^:..     J555555PPPP5YJ7!~^::::::^:!&G5555555555PPGBBGPY?!~^:::[email protected]#^:::^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^P&[email protected]                                            //
//                           :^:..               ?PPPP5Y?7!^^::::::^^^^^^^^:J&5555PGGBBGPY?7~^:::^^^^^^^[email protected]:^^^^^^^^^:^^^^^^^^^^^^^^^^^~~~~~~~!&Y~~~~~?BPG~!!!!!!!7##~                                            //
//                                         .^~7??J?7~^^:::::^^^^^^^^^^^^^^^^^B#BBGPY?!~^:::^^^^^^^^^^^^^~#@!^^^^^^^^!YPPGGGG5?^^~~~~~~~~~~~~~~!&Y~!!!!!P#5!!!!!!!!G&5:                                            //
//                                    :!7?JJ?7~^^:::::^^^^^^^^^^^::::^^^^^^^:[email protected]~^:::^^^^^^^^^^^^^^^^^^^:[email protected]^^^^^^^^J#[email protected]~~~~~~~~~~!!!!~Y#[email protected][email protected]#Y                                             //
//                                   .#G~^^::::^^^^^^^^^^^:::::^~!7JY~^^^^^^^^BY:^^^^^^^^^^^^^^^^^^^^!7J5BB?^^^^^[email protected]~~!!!!!!!!!!!Y#?!!!!!!7!Y?77777777JPB5!.                                          //
//                                    7&!:^^^^^^^^^^:::::^~7JYPBB#BG#P:^^^^^^:?#^^^^^^^^^^^^^^^~!?YPGGGGPG#~^~~~~~~~~!B555555#@Y~!!!!!!!!!!?GB7!77777777777777777777?YGG5!.                                       //
//                                     Y&~:^^^::::^^!7J5GB##BGPP55555#7:^^^^^^~&7^^^^^^^^^~7J5PGBGP5555555&[email protected]!!!!!!!!!!?P#BB777777777777777?????????7?YGGY~.                                    //
//                                      GB^:^^!?Y5GGB#BGP555555555555PB^^^^^^^^GP^^^^[email protected]?~!!!!!!!!!5BPG&#57!7777777JPBG5Y#57777777????J?7?????????????J5GGY~                                  //
//                                      :#B5PP5J7~: :YY555555555555555#J^^^^^^^JB^^^^[email protected]#B555555555##!!!!!!!!!!!5PPJ7!7777777JBGP5555P#?7?????????##5????????????????J5GGJ^                               //
//                                       .~^:     .^!5G555555555555555GG^^^^^^^7&!~~~7&GPGGGP5Y?J&#[email protected]!!!77777!!!!7?7777777?5GP55555BG7?????????Y#GBPJ??????JJJJJJJJ??JPGP?:                            //
//                                           ^!J5PPPYJ&B555555555555555#~~~~~~~!&7~~~~?YJ7!!~!!?JG#55555PGB##[email protected]&J!77777777YPPGG?7?????7?PBP5555&[email protected]@Y                           //
//                                          Y#YJ7~^^^:7&GY5555555555555#!~~~~~~7&[email protected]&?77777777Y#55BB?????????JGBG5YG#???????JJJ?BGJ:!PGYJJJJJJJJJJYPB&&#57^                           //
//                                          :G7:^^^^^^^7&G5555555555555#!~!!!!~?&7!!!!!!B#[email protected]??????7GBY5GB??????????YG#B5#P?JJJJJJJJJY&!   !PB5JJJJYPB&&#57^                               //
//                                           ^BJ^^~~~~~^7BB5555555555YGG!!!!!!!P#!!!!!!!5#[email protected]????????#G55GBJ???????J??YG&#@YJJJJJJJJJJ5&^    !GBPG#&#57^                                   //
//                                            :B5~~~~~~~~!5BP55555555P#?!!!!!!7&[email protected]????????Y&P55GBJ?JJ???JJ5PB&@&#JJJJJJJJJJJB#^     !YY7^                                       //
//                                             .5G7~~!!!!!~75BGP555PBG?!77777!P&[email protected][email protected]?JYPB#&&#BG55#GJJJJJJJJJJJ&#^                                                //
//                                               [email protected]&J777777??????????????????JY5PGBB&#YJ?JJJJJ????#&555G#B#&#BGP5555555&5JJJJJY5PGB&@5                                                //
//                                                :[email protected]?????????????????JY5PGB#BBGP55P&J?J???JJY5PG&@B5555PP555555555555G&PPGB#&#BPY7~.                                                //
//                                                  ^YGPJ7!777777777777777Y#&PY5&Y???????????JY5PGB##BGPP55555555##JY5PB#&&&#BGP555555555555555555Y77PPY?!^.                                                      //
//                                                    .75GPYJ?7777777??YP#&G5555G#?????JY5PGBBBBGPP555555555555555#####BGP5555555555555555555555J!.                                                               //
//                                                       .~J5PGGGGGGGGGP5P5555555&PYPGGBBGGP5555555555555555555555555555555555555555555555555Y7:                                                                  //
//                                                            .:^^^^^:.  .^7Y55555PPP55555555555555555555555555555555555555555555555555555J7^.                                                                    //
//                                                                          .:!?Y55555555555555555555555555555555555555555555555555555Y?~:                                                                        //
//                                                                              .^!?JY5555555555555555555555555555555555555555555YJ7~:.                                                                           //
//                                                                                   .^~7?JY5555555555555555555555555555555YJ?7~:.                                                                                //
//                                                                                         .:^~!7??JJYYYYYYYYYYYYYJJ??7!~^:.                                                                                      //
//                                                                                                    ...........                                                                                                 //
//                                                                                                                                                                                                                //
//                                      :JPPPYJ???JYY?::JP5: .JPJ.   ^?5PPPY!       ^YPGBBBG57.   .!YPPP5?: ~PBP7      7GBGJ.   .?GGJ.    :YPGBBBG5?: :!~::::.      .!YPGG57.                                     //
//                                     .#@@@@@@@@@@@@@&&@@@P [email protected]@@G :[email protected]@@@@@@@P      [email protected]@@@#&@@@#^ ?&@@@@@@@&!#@@@@!    [email protected]@@@@Y   [email protected]@@@B.   [email protected]@@@#&@@@&^[email protected]@&&&&&BY:  ~#@@@@@@@#~                                    //
//                                      !PGGB&@@@#BB#B5&@@@G.&@@@# [email protected]@@#GB&@@P      [email protected]@@[email protected]@@@[email protected]@@&GB#@@#[email protected]@@@?    [email protected]@@@@J  [email protected]@[email protected]@G   [email protected]@@B:[email protected]@@@[email protected]@@@@@@@@&7 #@@@&[email protected]@@5                                    //
//                                           ^&@@^  .  [email protected]@@[email protected]@@@P [email protected]@@! .^^:       [email protected]@@@&@@@@B::@@@P .:^:. [email protected]@@@~ ~~ [email protected]@@@#. [email protected]@[email protected]@@5  [email protected]@@@&@@@@#:[email protected]@@@#5&@@@@[email protected]@@@PYBPJ:                                    //
//                                           :&@@5     [email protected]@@@@@@@@J [email protected]@@&B##Y        [email protected]@@@@@@B?. ^@@@@B##B^  [email protected]@@@:[email protected]@[email protected]@@@? [email protected]@@@@@@@@? [email protected]@@@@@@BJ. :&@@@5 [email protected]@@@5 [email protected]@@@&G~                                     //
//                                           [email protected]@@@~    [email protected]@@@[email protected]@@5 [email protected]@@@&##Y        [email protected]@@@@@&P7. [email protected]@@@&&#G^  [email protected]@@@[email protected]@@&[email protected]@@&:^#@@@[email protected]@@@@@:[email protected]@@@@@@P7: .#@@@Y [email protected]@@@5 [email protected]@@@@J                                    //
//                                          .#@@@@5    [email protected]@@@^[email protected]@@#:#@@@?^7YPGJ      [email protected]@@[email protected]@@@#^[email protected]@@G^!J5GP:^@@@@@@&[email protected]@@@@#!&@@@@:.&@@@@@[email protected]@@[email protected]@@@&~.&@@@##@@@@@[email protected]@# [email protected]@@@@:                                   //
//                                          [email protected]@@@@G   ^@@@@@!&@@@@^#@@@&&@@@@@:    :&@@@[email protected]@@@@[email protected]@@@&@@@@@?^@@@@@@Y^@@@@@[email protected]@@@P ^@@@@@@?#@@@P.&@@@@[email protected]@@@@@@@@@[email protected]@@@B&@@@@#.                                   //
//                                          ~&@@@#~   [email protected]@@P:#@@@Y [email protected]@@@@@@G~     :&@@@! [email protected]@@#^ Y&@@@@@@#J. [email protected]@@@5  [email protected]@@#^[email protected]@@#^ .B                                                                              //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JTJREWARDS is ERC721Creator {
    constructor() ERC721Creator("JTJ - REWARDS", "JTJREWARDS") {}
}