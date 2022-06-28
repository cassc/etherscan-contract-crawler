// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0xfarah
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                    :Y:            :5G:                     //
//                                                                    :BG:          7GBB7                     //
//                                                                     5#P:        JBBBB5                     //
//                                                                     !BBG7      YBBBBBB5:                   //
//                                                                      5BBB5:   7BBBBBBBB5                   //
//                                                                      :GBBBG~ .GBBBBBBBBP                   //
//          :5P5?!^.                                                     ^GBBBB~!BBBBBBBBB7                   //
//          !#BBBBBG5?~.                                                  ^GBBBBGBBBBBBBBBGPY~                //
//          ^BBBBBBBBBBGJ^                                                 :PBBBBBBBBBBBBBBBBB7               //
//          !BBBBBBBBBBBBBY^                                 .:^^:          :GBBBBBBBBBBBBBBBBB~              //
//         ?BBBBBBBBBBBBBBBB7                          .:!?YPGBBBP:          ^BBBBBBBBBBBBBBBBB5              //
//        ^BBBBBBBBBBBBBBBBBB?                     :~?5GBBBBBBB5!.            7BBBBBBBBBBBBBBBBB:             //
//        :GBBBBBBBBBBBBBBBBBB?                :!JPBBBBBBBBBP7:                7GBBBBBBBBBBBBBBB:             //
//         :5BBBBBBBBBBBBBBBBBB~           .~JPBBBBBBBBBBBB?                    .JBBBBBBBBBBBBBJ              //
//      :7YPGBBBBBBBBBBBBBBBBBBP.       .~JGBBBBBBBBBBBBB5^                       !GBPGBBBBGPY~               //
//     !GBBBBBBBBBBBBBBBBBBBBBBB!     ^JGBBBBBBBBBBBBBB5!                          :~ .:^^:.                  //
//    :GBBBBBBBBBBBBBBBBBBBBBBBBJ~?^!5BBBBBBBBBBBBBBPJ~                                                       //
//    !BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB5^.                                                         //
//    5BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB?                                      .^~^                 //
//    GBBBBBBBBBBBBBBBBBBBBBBGGBBBBBBBBBBBBBBBBBG!                                   .~?5GBB!                 //
//    ^5BBBBBBBBBBBBBBBBBBBP7.YBBBBBBBBBBBBBBBBY:                  !55YJ?!~:       ^JGBBBBB5                  //
//      ~YGBBBBBBBBBBBBBGY~. :BBBBBBBBBBBBBBB5~                    .7B#BBBBGPJ~. :JBBBBBBBJ.                  //
//        .~?5PGGGP5Y7~^.    .GBBBBBBBBBBBB5~                        !5BBBBBBBBPPGBBBBBBBBY                   //
//             ....           !GBBBBBBBBPJ^                           ^BBBBBBBB#PGBBBBBBBP^                   //
//                             :?5PPY?!:                               7GBBBBBGY:.!JJJJ?~.                    //
//                                                                      .~777~:                               //
//                                                                                                            //
//                                              ...::^^~!!777??77~~~!7???7!~~~~~~~~~~~^^::..                  //
//                                     ..:^~~~7JYYY?7!5PPGGGGPPP5!!Y5PGGGGP5YJ?7!?YPP55P555YJ?7!~:..          //
//                                .:^~~~?Y5YJ?5PPPPPPGGGGGGGGBGPGGGGGGGGGGGGPPPPPP555PPPPPPPGGBGP5J~~~:       //
//                           .:^~~~!?J?7PPPPPGGGBBGGGPPPPPPPPPPP5YY55PGBBGP5YY5PPPPPP5PPPPPGGP5555PJ??JJ^     //
//                       .:^~~7??7!5PPPPPP55PPGGGGP55PGGGGGGGPP5YY55PPGGGGGGGBBGP5PPPPPGGGGGPPPPP55PPGGPY.    //
//                    :^!!!777GBBGP5YY5PGGGPP5YJJ???YYYYYYY55PPPGGGGGP5YY5PPPPPPP55555PP5Y555YY55PGGGPJ~77    //
//                 :~!!!.^5GBBBBGP5JY55PYJ?????JY55Y55YYY55PPPP5YYY555PGGGGGGGGGPPGBGP5YJJ5PPGBBBG5Y?~. ^J    //
//              :~!^.^Y5YYGGGPP5555PPGGGGGP5PPGGPPPGGGGGGPP555YJJ5PPPP5555PGGGPPPPGGGGGPYJY5P555J!^.    :J    //
//            :!!~!?YPGPPP55PPPGGBBBP5555PPP5555PPGPPPP5Y55PGGGGGGGPPGGGPP5YYY5PGPPP555Y5PP5J!^.        :J    //
//          .!77YPP5YY5PPPPP555PGBBGGP5Y5PPGGBBG55PPGGGGBBBGP55555PP5YYY5PGGBBG55PPGGGPY?~:.            :J    //
//         :??PBBGP5JY55Y?JY5GGBBBGPYYJY55PGGGBGGGPP555555PPGGGGGGP5YY55PPPGGGGGPYJ7!^.                 ~?    //
//         75BBG555PPGGGGP5P55YY55PPGBBBGGP5YY555PPGGGGGGPP555555PPGGBBBGP5YJ?!~:.                      7!    //
//         ?77Y5PGGP555GBBBGP5YY55PGGBGP5YJY5PGGGPP555PGBBBGG5YYYYYYYJ?7!^:.                           :J:    //
//         ~?  .:~!7J5PGGPYJJ?Y5PGBBBBGP55JY555PPGGBBBBBBGYJJ??7!~^:.                  :. .           .!?     //
//          ?~       .:^~~!777???JY55PPP5YYJYYYJJJJ???7!~^::.                             .     .. .  :?^     //
//          .J:                     ..............                                         :. : .:.. .^?      //
//           ~?                                                        :                 ....  ...  ..?^      //
//           .J. :                                             :      ..               . .    ..    :7!       //
//            ?^  .: ..                                        :      :             :.       ..   .:7!        //
//            ~?:    .. :.          .. .. .. ..                ...   .: . .: .. . :     .:  :.   .:?~         //
//             :!!^       .:    ..:           .                  . .  .:.    .. .    ...  :      ~?^          //
//               .~?^        : .:       .......................      : ..  ..       ..  :      .77.           //
//                 :J.:::.      .  ..::.........................:.   .. .  .   .  : .: .^~.   ~?^             //
//                  7!.  .::::..:^::    ::.::.::          ...::. ..   .. .. :. . .:   .:?!!~!7~.              //
//                  :?::    .:^: ...... :. .:...               :: .    :..      .:.:.:.~7  ..                 //
//                   J^^      :: .. :..: .: ..                 :: :   ..:    ...: .:.:.?~                     //
//                   7!::.    .^    .  .  .                   .:  :....   .. ..   :^. .J^                     //
//                   ^J:..:..::.                            .::    .        ..  .:... :J:                     //
//                    !7... .  :::::.        ::...   .....::.             ... .:.   .. ^?:                    //
//                     ^7~: ...^...:.:.        ..........                ..  ^:       ..:7!.                  //
//                       :!!^.:^.:    .:.           .  .  .  .  .  .  . .  :::^       . . ^J                  //
//                         .^7~^ :      .^:      .. .  .        .  .  .  .:^  ::      .   ^?                  //
//                            !? .       :.:.    .                    .::::    ^      ..  ?^                  //
//                            :J:.      :   ^.:. . ....        ...::^:::. ^.   ^.     .  ^J                   //
//                            .J~.    ..    ^:        . ..   .:. .. ....  :.   ::    .. .J^                   //
//                             77.:     .. :^                   .:..::::....   .:   .. .?~                    //
//                             ^J^:.....:::.                  .. .:.:  .  ..   :: ..  :?^                     //
//                             .J:. .... .  : .            ...:..:..:..   :    ^..   ~7:                      //
//                             .J::    ....    ..       ..:.  .::.  ..   :    ::   :7~                        //
//                              J^.    ..        .:.....  .:...  :...   ..   ::  .!!.                         //
//                              :7!.    :..   .. ..  .:  ....:  ..     ..   ::.:!7:                           //
//                                ~?^. :: .. .. ...   :..:   :..      :.  .^:^!7^                             //
//                                 ^?!  ^   .:.  .:.:.   ::...       :   .^^!7^                               //
//                                   ~!~!!~~::::.:  .:.  ..        ..  :::~7^                                 //
//                                     ....:77....:. ..            ..::~!7^                                   //
//                                           77. ::                 :~7!:                                     //
//                                           .J^  .:.            .^!7~.                                       //
//                                            ^?:   ::         .^77^.                                         //
//                                             ^7~^:.:::.   .:~77^                                            //
//                                               .:^~~!!777777~:                                              //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract farah is ERC721Creator {
    constructor() ERC721Creator("0xfarah", "farah") {}
}