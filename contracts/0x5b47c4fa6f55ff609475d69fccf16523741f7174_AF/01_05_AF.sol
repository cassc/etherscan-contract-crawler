// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AFIFWM
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                   .:!J5    //
//                                                                                                .^7Y555Y    //
//                                                                                             .:7Y55YJJJJ    //
//                                                                                          .:7Y5555YY5YYY    //
//                                                                                        .!Y5P555YJJJJJJY    //
//    ^.                                                                               .~J5P555Y5555YJJY55    //
//    ?7!~:.                                                                         :?5PPP555YYYYYYY55YYY    //
//    77???7!^:.                                                                  :!YPPPP55Y555YY55555555Y    //
//    ??7?7?????7~:..                               .:~7?7!~:                  :!YPGPP5P55P5YY555PPP555555    //
//    ?7!7??J?77?JJJ?7~^..                       .:~?YPGP55Y7~^.            .~YPGPPPPPPP555555PP555PP5555Y    //
//    !7??777?????JJ??J??7!^7^.                .:^?Y555Y555YJ55J!.       :JY5GPPPPPPPP55P5Y5PPPPP555PP555Y    //
//    Y?7!!?J?777?J?777777!:7?:.               ..7YYY55555PPPPPP5Y^     .5P5PPPPPPPPPP5555YPPPPPPP5555P555    //
//    YJJJ??!!7?YJ?77!!7~!~.~:..             ..:75J?J55PPPPPPP555YY:    .!JJ55PP5P555PPPPP5YPPPPPPP5555P55    //
//    Y5PY!??J?JJ77!!!~~~!^.:..              ..?5YJ?JY55Y55555YJ??J^     .!JY5555555PPPPP5P5YPPPPPP55YYYYY    //
//    YPY77J???JJ??7!~~^^^::^..          ..::^75YY??JYYJJJJ?YYJJ7!^.      :JYY5555555P55PP5555PPP5P55YJJJJ    //
//    5YJJ???JJ???7!!~~^:^~^^:..          .:7Y555J?77?YJ?JJ?J?!!^!:       :Y55555555PP5555555555555555555Y    //
//    J?????77777??7!!~~!7!~^~::.     . .:!J55Y55JJJ?J5YY5P???::!Y:       !P555PP555YYYYY5555PP555YYYYYYYY    //
//    ??????77!!~^^~!!!~!!!!^~!^:. ..!777?Y555555YJ5Y??YY5Y~~^^Y5P^      :5P555P555555YYY5PPPPPP55555YYYYY    //
//    ???JJJJJ77777??7777!~~^:~7~^..^5PY5PP5555P5YJYPJ77?J7^:!5PPP.     :5P55P5PPPPPP555PPPPPPP555555YYYYY    //
//    ?????JJJJ???J??JJ??7~!!~^!7!~^:7PPPP55PPPP55YJ555YJ?~?JYPPP5.   .~5P55PPPPPPPPPPPPPPPPPPPP55555555YY    //
//    ?JJJJ?JJJJ????J?77777!!!!~777!!?Y5555P5555YY5555555YY5J7PPP5. :!5PP55PPPPPPPP55PPP555PPPP55555555555    //
//    J???????????JJ?777??~!7~777~!777Y5YY?~?5PYYY555YJJJ5PYJ!J5Y5?7YPP55PPPP5PP555PPPPPPPPP555555555555YY    //
//    ??JJJ?JJYYYYJJJJJ?7!7???7????J??J7JY?JPPPP5P55YYJYY5PYJ77PJ555YJYPPPPPPPPP5555PPPPPP5555P5YYY5555555    //
//    ?777!7JJJJJJJJJJJ?????????J?7?J?JJ55YPP5YP5P55555YY55?Y!^P!P55PJ75PPPPPP555PPPPPPPPPP555PJ:. .~J55YY    //
//    .  :~?JJYJJJJJJJJJ????JJJJJYYYJYJYP5YYPYJ5PPPPYY555P5!Y7:Y~5555?^?5PPPPPPPPPPPPPPPPP5555??~     .~JY    //
//      .^!7JJJJJYJ??JJJJJJJJJJJYY555P5555P55J75PGGGP55PPY!?J?!~!?JYYJ?J!YPPPPPPPPPPPP55555PP5?:         .    //
//        :7?JJJJ?JJJJ???JJ77??J5555PYJ5PPGP5Y!YPPPPPGP?!7?5577!^~^Y5Y55J5P555555555555PPPPPPY~.              //
//         :7JJJJJJ???JJ?77??JYJYYY55?!YPP555YYYY5PPPY!?55?JGG77?7^??PPYJJYP55555555555555??JJ!               //
//         .::::7JJJJJ?77?JJYJJJY5Y55Y7Y555YJ5PPPPPY7~?GPY7JP5!5???!^?Y5J!!555555555555PPP7                   //
//             .!7J?7??JJYYJJJY5Y~~5PYJ5P5JJYPPPPY77YY?P5Y7YP?5P?7??7!?PJ!!5555PPPPPP555Y7~                   //
//                :~YYYYYJJJYY?:. JY5PPPGJYGPPPP!!?5J5Y5PY7555PJ5J~7J?7YY~!755PPPPPPPPY!~                     //
//                .77?YJ??Y?~.   .~.7PPPPYPGGPPPJYY55J5Y5YJPYPY5J7?7J7?J?:~JJPPPPPPPPPP!                      //
//                  .!~..:.         .7PPPPPP555YYYPY5JYJY?JYYYYY?!7Y?!~77~^..:75PJYPP~^:                      //
//                                   .^!?J??J7^JJYJ??J??JYY?JJJ?JJ!??!:!!:     .^: :7^                        //
//                                     .:^~!!^^Y5P55JJJY557JY?5JJ??JJ?^:.                                     //
//                                         .?5PGP5YYY55YY7YGJJ5JYYJ5Y?.                                       //
//                                       .7PPPPP5YPP55YJ?5GPJJYJ55Y5PJ^                                       //
//                                      ~5PPPPP55PPYY5JJ5PGYYJYYP555P57.                                      //
//                                    .?PPP5PPPPPP555YY5PGPJ5YJPGY555PY^                                      //
//                                  .^YPP55PPPPPP5PPY5PPGGY5PYYPPY5555P!.                                     //
//                                 :?5P5Y5PPPPPPPPP55PPGG5JPPJ5PPY5555P!:                                     //
//                              .^?5P5Y5PPPPPPPPPPPPPPPGPJ5P5YYY5J555Y5?^                                     //
//                           .^7YPPPYY5PPPPPPPPPPPPPPPGGYJPP55!YY?555YYJ~.                                    //
//                         .~J5PPPYJ5PP5PP5PPPPPPPPPPGG5?5PPY?7P!J555YYJ!.                                    //
//                       .!YPPPP5JYPP55555PPPPGGGGPPGGP7?YP5J!5J~Y555YYJ!.                                    //
//                     .75PPPP5JJ555555Y5PPPPGGGGPPGGP!7JJPJ!7Y7J5555YY?~                                     //
//                   .7PGPPP5J?Y5YYY5PYYPPPPGGGPPPGGP7~J?557^?JY5555YYJ7:                                     //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AF is ERC721Creator {
    constructor() ERC721Creator("AFIFWM", "AF") {}
}