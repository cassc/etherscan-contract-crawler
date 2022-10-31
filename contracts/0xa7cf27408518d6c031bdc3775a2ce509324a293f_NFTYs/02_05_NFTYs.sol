// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NFTYSkateSpots
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//     _____  ___     _______   ___________   ___  ___                                                        //
//    (\"   \|"  \   /"     "| ("     _   ") |"  \/"  |                                                       //
//    |.\\   \    | (: ______)  )__/  \\__/   \   \  /                                                        //
//    |: \.   \\  |  \/    |       \\_ /       \\  \/                                                         //
//    |.  \    \. |  // ___)       |.  |       /   /                                                          //
//    |    \    \ | (:  (          \:  |      /   /                                                           //
//     \___|\____\)  \__/           \__|     |___/                                                            //
//                                                                                                            //
//      ________   __   ___    _______                                                                        //
//     /"       ) |/"| /  ")  /"  _  \\                                                                       //
//    (:   \___/  (: |/   /  |:  _ /  :|                                                                      //
//     \___  \    |    __/    \___/___/                                                                       //
//      __/  \\   (// _  \    //  /_ \\                                                                       //
//     /" \   :)  |: | \  \  |:  /_   :|                                                                      //
//    (_______/   (__|  \__)  \_______/                                                                       //
//                                                                                                            //
//      ________     _______       ______     ___________    ________                                         //
//     /"       )   |   __ "\     /    " \   ("     _   ")  /"       )                                        //
//    (:   \___/    (. |__) :)   // ____  \   )__/  \\__/  (:   \___/                                         //
//     \___  \      |:  ____/   /  /    ) :)     \\_ /      \___  \                                           //
//      __/  \\     (|  /      (: (____/ //      |.  |       __/  \\                                          //
//     /" \   :)   /|__/ \      \        /       \:  |      /" \   :)                                         //
//    (_______/   (_______)      \"_____/         \__|     (_______/                                          //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                             .:^^~!!!77!!~~^:.                                              //
//                                      .^!J5G#&@@@@@@&&&&@@@@@&#BPY7~:                                       //
//                                  :7YB&@@&BPY?!~^:.......::^~7J5G#@@@#P?~.                                  //
//                              .!Y#@@&GJ!:   .:^!?JYYYYYYYJ?7~^.   .^[email protected]@&P?:                               //
//                           .!5&@@G?^   ^7YPB&@@@#[email protected]@@GPGB#&&&#G5J~.  .!5#@@G?:                            //
//                         :J#@@P7.  ^?P&@&@@@@@@Y    !&@P!~  .^[email protected]&#@@#5!.  ^Y#@@P~                          //
//                       ^[email protected]@#J:  ~Y#@@@Y^[email protected]@@@@&: ~?  ~&@@G  .BG#B: :[email protected]&P7.  [email protected]@B7                        //
//                     :[email protected]@B7  [email protected]@5~:Y. 7#@@@@J  ^~^  ^#@!  [email protected]@G.  ^?~:7&@@@P~  ^[email protected]@B!                      //
//                    7&@#7  :Y&@B&@P.      :7P#!!J&@@[email protected]@P   ~7!B&&@B5P&@G!  ^[email protected]@P:                    //
//                  :[email protected]@5. .J&@G~.5&@#^  :[email protected]@@&BGPPPPPPB#&@@&GY!::7&@@J  ..J&@G^  !#@&7                   //
//                 ~#@&!  [email protected]&! :J!::[email protected]@@#57~:.          .^!JG&@@PGG^?5~ ??.^[email protected]@J  [email protected]@Y                  //
//                !&@B^  [email protected]@##:  :?^  [email protected]@@G?^                     [email protected]@&5^.^  [email protected]#&##@G:  [email protected]@5                 //
//               ~&@B:  [email protected]@7 ?#BGP~ ?#@&Y^                         [email protected]@@@@P!!JG5?^ :[email protected]#^  [email protected]@5                //
//              :#@&:  [email protected]@BJ. ^P&[email protected]@5:                          7#@@@@@@@@G^   :7. [email protected]#:  [email protected]@J               //
//              [email protected]@!  [email protected]@7 ..    [email protected]@&!               .::::.     ^[email protected]@@@@@@@@@@5?7 ~?. ^@@B.  [email protected]@^              //
//             [email protected]@P  :&@#YPGBBGY?&@#^           :75G#######[email protected]@@@@@@@@@@@@@@@P~:[email protected]@@J  [email protected]@G              //
//             [email protected]@~  [email protected]&::#@@@@@@@@~          ~P&#57^:....:~J&@@@@@@@@@@@@@@@@@@@#Y??JP&@&:  [email protected]@~             //
//            :&@B  .#@5  :^[email protected]@Y         :[email protected]~   [email protected]@@@@@@@@@@@@@@@@@@Y   .. ^&@?  [email protected]@J             //
//            [email protected]@5  ^@@! ~!~^:[email protected]@^        ^#@7   [email protected]@@P?5&@@@@@@@@@@@@@@@@@@@@@~ 7##B^ [email protected]  ^@@G             //
//            [email protected]@J  [email protected]@Y?#@@@&&@@&.       [email protected]!  ~#@@P?P7  ^&@@@@@@@@@@@@@@@@@@@@5  ::. [email protected]  .&@B             //
//            [email protected]@J  [email protected]@?~##Y#@@@@&.       [email protected]   :5&@B.    [email protected]@&55PB#@@@@@@@@@@@@@@BJ77?Y#@@G  .&@B             //
//            [email protected]@5  ^@@! 5Y 7P5#@@~       [email protected]     :Y&&[email protected]#J:    ^@#[email protected]@@GG#&@@7^[email protected]  ^@@G             //
//            :&@B  [email protected]       [email protected]@P       [email protected]       .~?JJ?~.      :@B       [email protected]@#.   .: :&@!  [email protected]@J             //
//             [email protected]@~  [email protected]&JY5PGPY?#@@?      [email protected]#GG!     .:::.     :[email protected]      [email protected]@@BPYJ!  [email protected]#.  [email protected]@~             //
//             [email protected]@P  .#@@#P?~:  [email protected]@@7     [email protected]@@&:7JJYPBBPGBG5YJJ:[email protected]@@P     [email protected]@#[email protected]@@&~~&@7  [email protected]@G              //
//              [email protected]@!  [email protected]@? ^~. ^5B#@@J    ^@@@@~:^^[email protected]~#G!~^^:[email protected]@@5    ~#@@B: Y7.:[email protected]@5   [email protected]@~              //
//              :#@&:  [email protected]@#5: .^: ^#@&.   :@P^^^    :&Y7?#Y    .^^~&5    [email protected]@&: .^:7  [email protected]  [email protected]@J               //
//               ~&@B:  [email protected]@?  :!JG#@@B  57^&Y       :YPPPP!        #Y^Y: [email protected]@@G?!?P^ [email protected]  [email protected]@5                //
//                ~&@B^  !&@GB&@@@@@@P .&@&@Y                      #&@@~ [email protected]@@@@@@&[email protected]   [email protected]@5                 //
//                 ~#@&!  :[email protected]@@@@@@@@Y :&@@@J                      [email protected]@@! [email protected]@@@@@@@@&!  [email protected]@Y                  //
//                  :[email protected]@5.  ^^~^^~~~~. ^@@@@?                      [email protected]@@?  ~~~~^^~^^.  !#@&7                   //
//                    7&@#7   [email protected]@@@J                      [email protected]@@BYYYY55PY~   ^[email protected]@P:                    //
//                     :[email protected]@B7  [email protected]@@@@@@@@@J                      [email protected]@@@@@@@@#J:  ^[email protected]@B!                      //
//                       ^[email protected]@B7.  :7P&@@@@@@J                      [email protected]@@@@@BJ~   ^[email protected]@B7                        //
//                         :[email protected]@#?.   .!JG#@@J                      [email protected]&B57^    ^[email protected]@B7                          //
//                           :Y&@#?.     .^JJ                      B!:      [email protected]@B!                            //
//                             :J&@&J:     :?                     .5      [email protected]@G!                              //
//                               .J#@&Y:   .!                     .7   [email protected]@P~                                //
//                                 .?#@@5^  :                     .: .?#@@5^                                  //
//                                   [email protected]@P~                       :Y&@&J:                                    //
//                                      [email protected]@G7.                  [email protected]@#?.                                      //
//                                        ^[email protected]@#J:             [email protected]@G!                                         //
//                                          :J#@@P!.        ~5&@&Y^                                           //
//                                             ~5&@&5!:..~J#@@G!.                                             //
//                            ..:^^~~!!77??JJJJJ7^7P&@@#&@@G?^!JJJJJ???77!!~~^^:..                            //
//                       :JPB##&@@@@@@@@@@@@@@@@@#5!^~7?7~^[email protected]@@@@@@@@@@@@@@@@@&##GPJ.                       //
//                       :7J5PGB##&&&@@@@@@@@@@@@@@@@B5Y5G&@@@@@@@@@@@@@@@@&&&##BGP5J!.                       //
//                               ..::^^^~~~!!!77777????JJ???777777!!!~~~^^^::..                               //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NFTYs is ERC721Creator {
    constructor() ERC721Creator("NFTYSkateSpots", "NFTYs") {}
}