// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: jpg.exe
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                      /$$$$$                                                                                    //
//                                     |__  $$                                                                                    //
//                                        | $$  /$$$$$$   /$$$$$$       /$$$$$$  /$$   /$$  /$$$$$$                               //
//                                        | $$ /$$__  $$ /$$__  $$     /$$__  $$|  $$ /$$/ /$$__  $$                              //
//                                   /$$  | $$| $$  \ $$| $$  \ $$    | $$$$$$$$ \  $$$$/ | $$$$$$$$                              //
//                                  | $$  | $$| $$  | $$| $$  | $$    | $$_____/  >$$  $$ | $$_____/                              //
//                                  |  $$$$$$/| $$$$$$$/|  $$$$$$$ /$$|  $$$$$$$ /$$/\  $$|  $$$$$$$                              //
//                                   \______/ | $$____/  \____  $$|__/ \_______/|__/  \__/ \_______/                              //
//                                            | $$       /$$  \ $$                                                                //
//                                            | $$      |  $$$$$$/                                                                //
//                                            |__/       \______/                                                                 //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                :~?Y5J7~:                                              :~7J5Y?7^                                //
//                               [email protected]@####&&&BP?^                                      ^?PB&&&###[email protected]@P.                              //
//                              ^@@Y~5GGPP5G#@@#5!.     .:^~!?????????7!!^:.     .!5#@@#[email protected]@7                              //
//                              [email protected]@7P&####BGP5PB&@&P7JPB#&@&##BBBBBBBB##&@&#BPY?P&@&G55PGB######7&@?                              //
//                              ^@@JP#########BGP5G#&#GY?!^:.          .:^~7JPB##G55GB#########B?&@?                              //
//                              ^@@JP#############G5J~.    ...::::::::...     :75GB############G?&@?                              //
//                              ^@@Y5##############&#B5?^^^^^^^^^^^^^^^^^^^^!YG#&##############[email protected]@?                              //
//                              .#@PY###########&#GY7~^~!7JY~~~!!~~7PB?^~~7~^^~?5B#&###########[email protected]@!                              //
//                               [email protected]?B#########G?~^~JP#&@@@#.       ~B!  ^@@&BP?~^~?P#&########[email protected]&:                              //
//                               [email protected]&7G#####&#Y^:7P#@@@@@@@@P.        .  [email protected]@@@@@@&P?^^JB&#####[email protected]                               //
//                               [email protected]@?5#####Y:^Y#@@@@@@@@@#G:            [email protected]@@@@@@@@@@&P~:?B&###G?&@J                               //
//                               .#@P?B#&P^:[email protected]@@@@@@@@@@&7.            [email protected]@@@@@@@@@@@@@G~:5&#&[email protected]@^                               //
//                                [email protected]&!PPJ.7&@@@@@@@@@@@@&^             .#@@@@@@@@@@@@@@@@[email protected]#.                               //
//                                [email protected]@~^[email protected]@@@@@@@@&@@@@@5.            :&@@@@@@@&&@@@@@@@@G.7~.&@B.                               //
//                               [email protected]@[email protected]@@@@@@@[email protected]@@GY5:           [email protected]@@@&?7#@@@@@@@P.?.!&@G^                              //
//                              [email protected]@? ^!^@@@@@@@@#[email protected]@@?!!P.           [email protected]@@#[email protected]@@@@@@@7~! !&@@J                             //
//                              [email protected]  7:[email protected]@@@@@@@# [email protected]@&&&&G.P^          .B?~&&&&&@#[email protected]@@@@@@@B:?  Y#@#.                            //
//                             .#@P [email protected]@@@@@@@@J:5####B7!#!          .BP:Y#&##B7~#@@@@@@@@&^7. [email protected]&:                            //
//                              #@P :?:&@@@#PYY?~!??YPP5JYB&!          :##P?YPPP5P#&@@@@@@@@@~7: [email protected]&:                            //
//                              #@P :7:&@@#:       :^^^^^:.!.          .!^.^^^^^^^:^??GB#@@@@~!: [email protected]&:                            //
//                             .#@P .?:&@@Y                     :..:.                 ..:[email protected]@&^7: [email protected]@:                            //
//                              #@G..?:[email protected]@G:.............       ~7!7^      [email protected]@#:[email protected]@G.                            //
//                              [email protected]&~.7^[email protected]@@J::::::^^^~~^^        :?.       :^~~^^^::::::[email protected]@@Y^?.^&@P                              //
//                              [email protected]@5.^7:[email protected]@@G!^^~~!!~^^~~.   :^^^^^^^^^:  .^~^^~!!!~~^[email protected]@@B:7^[email protected]@~                              //
//                               [email protected]@? !~^[email protected]@@G^::..    ..     ..    ...    ..    ...:^?&@@B^!! [email protected]@J                               //
//                                [email protected]@P^J7:JBB:                                        :JBY:[email protected]@J                                //
//                                 7#@&GY7J?~!^.                           .        .:~~^^7~J&@B~                                 //
//                                  [email protected]@5!5GJ~~~~^:..                  [email protected]@J                                   //
//                                   .&@Y ~!Y~^~~~~~~~^^::..............~?GB&#GPJ7!~~~!7   [email protected]&.                                   //
//                                  [email protected]@B!~^?.  .:^^~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^::. .Y7?J#@@?                                   //
//                                 7#@@@&###J^^::..  ...:::^^^^^^^^^^^^^^^::.... ...:^^JB##&@@@B~                                 //
//                                [email protected]@@@@@&&? ..::^^^^^^^^::::::::::...:::::^^^^^^^^^:.. ^B&@@@@@@?                                //
//                               [email protected]@BB&@@@@&B5J!^:.    ....?5Y??J5JJ?Y5Y?....      .^[email protected]@@@@B#@@!                               //
//                             [email protected]@J.:!YG#@@@@@@@&#BP5J?7!~5?777Y~ ?JJ!^?:^~!7?J5GB#@@@@@@&B57::[email protected]@J                              //
//                            [email protected]&!     :~7YPBB#@@@@@@@@@@@@@@@@#. [email protected]&#&@@@@@@@@@@@@@@BGY?!^.    [email protected]@P.                            //
//                           :[email protected]#~         .?. :7J5PGB###&&&&&&@5 :#&&&&&&&###BGPP5J??J:.         !&@G.                           //
//                          [email protected]#^          :7  !~ ...::^~~~!!7?5! !5J?!~~~~~77!~~7~.  7.           !&@G.                          //
//                         [email protected]&^           ^!  7.          .~~~??!G?.^7^  .7:     :7. !~            [email protected]@P                          //
//                         [email protected]&~            !^ .?          .J!^GBPGP:!5BG! ~!       7^ ^!             [email protected]@J                         //
//                        [email protected]@J...          7^ .?          :J?YB###P?JGGJ?..7^.   .~!  :7           [email protected]@!                        //
//                       [email protected]@GJJ7^~~.       7: .?          .!!#&#&&&&&#BY~  .^?~!7^:   .7        .^^[email protected]&:                       //
//                      .#@#55P!^!?.       !^ .?            ^?J?JJJJPP7^     ? ^!     .?        ^?7?JJ??&@P                       //
//                      [email protected]@J?J7^!7~        :!^^?~:::::::::::..:^~~~~^::.:::::? ~7::::^~~         [email protected]@7                      //
//                      [email protected]#!?!!?!7           .:::::^^^^^^^^^^^^^:^^::^^^^^^^~? !7:::::.          .?J??77?#@5                      //
//                      [email protected]@J7!7??.                                          .7^7:                 :?????J&@Y                      //
//                      [email protected]@?:^~7^                                            ...                   ^~^:[email protected]@^                      //
//                      ^&@B!^.                                                                      :^[email protected]&^                      //
//                     :#@@7 :J~                                                                    .Y: [email protected]@#:                     //
//                     [email protected]@B: .5^                            ....          .                          ?! [email protected]@5                     //
//                     [email protected]@5  ~?                             .......     .....                        ^Y. ?&@B                     //
//                     [email protected]@7 .Y~                             ..................                        J~ !&@#.                    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract merk is ERC721Creator {
    constructor() ERC721Creator("jpg.exe", "merk") {}
}