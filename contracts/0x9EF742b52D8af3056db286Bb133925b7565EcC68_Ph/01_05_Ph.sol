// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Phenomenon
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                          !~                                                    ~!                          //
//                        .JB?                                                    7BY:                        //
//                       :PGG5                                                    YGGP^                       //
//                      :PGGGG7               ..::^^~~~~~~~~~^::..               7GGGGP:                      //
//                      JGGGGGG?        .^!?JY5PPGGGGGuyo66GGGGGP55J?!^:        7GGGGGGY                      //
//                     :GGGGGGGG5~  :!J5PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGP5J!:  ~5GGGGGGGG^                     //
//                     !GGGGGGGG5Y?YGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG5?Y5GGGGGGGG!                     //
//                     !GGGGGG5JYPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPYJ5GGGGGG7                     //
//                     ~GGGGPJYGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGYJ5GGGG!                     //
//                     :PGGYJPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPJYGGG:                     //
//                      JBJJGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGJJBY                      //
//                      ^JJGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGJJ^                      //
//                       !GGGGGGGGP5YYYY5PPGGGGGGGGGGGGGGGGGGGGGGGGGGPP5YYYYY5GGGGGGGG7                       //
//                      .5GGGGGPJ7777777777?J5GGGGGGGGGGGGGGGGGGGG5J?7777777777JPGGGGGP.                      //
//                      ~GGGGGJ!77????????77777JPGGGGGGGGGGGGGGPJ77777????????77!JGGGGG~                      //
//                      7GGGGJ!???????????????77!?PGGGGGGGGGGP?!77???????????????!?GGGG?                      //
//                      ?GGG5~???????????????????7!JPGGGGGGGJ!7???????????????????~YGGGJ                      //
//                      7GGG77???7!~!!!77???7??????7!5GGGG57!??????7???77!!!~!7???77GGG?                      //
//                      ~GGG!7???!!!!^7?!!777!!77???7!JGGJ!7???77!!7?7!!??^!!!!???7!GGG~                      //
//                      .PGG!7??????~YGGG5?!!77!~!77??!??!???7!~!77!!?5GGGY~7?????7!GGP.                      //
//                       7GG77?????!7GGGGGGPJ!!7?7!!7??7!??7!!7??!!JPGGGGGG?!?????7!GG?                       //
//                       .5GY~?????!?GGGGGJPGPJ!!7??777??777??7!!JPGPJGGGGGJ~?????!JGP.                       //
//                        ^GG!7????7~PGGPPJ?YP5GJ7!777!7?!777!7JG5PY?JP5GGP~7????7!GG~                        //
//                         !GP!7????!!5GYJY77??55GP!~77??77!!5G55??77YJYGP!!????7!5B7                         //
//                          7GP!7????7~7?!!!!!7!J57!7777777?!75J77!!!!!??~7????7!5G?                          //
//                        .^^7J?~!??!!!!7777777!7~~!7?JJJJ?7!~~7!7777777!!!!??!~?J7^^.                        //
//                       .7??7777!??77???????????7!5GGGGGGGG5!7???????????77??!7777??7.                       //
//                       .7???????!~!77?7????????7!YPGGGGGGP5!7????????7?77!~!???????7.                       //
//                        :7?????!:!YY?!77777777777!77????77!77777777777!?JY7:~??????^                        //
//                         :7????!!77G&JPBGGP!75YYJJ~7????7~JJJY5?!PGGBPJ&G77!!????7:                         //
//                          .~????7?7!PBJ&#&5YJ&##&G7Y&##&Y7P&##&JY5&#&YGG!7?77???!.                          //
//                            :!?????7!GJB&PY#?B##B?B?B###?B?B###?#Y5&BJB!7?????!:                            //
//                              :~7???77Y5GJ##JG##JP&YP##PY&GJ##GJ##JGPY77???7~:                              //
//                                .^!7!7!~J###55&PY##GJ##JG##YP&PY###J!!7!7!^.                                //
//                                   .::7!JB##GJ#?####JBB?####?BYP###J~7^:.                                   //
//                                      .~775B#JJP####55P5####GJJ#B577~.                                      //
//                                        .~!7Y!J&####BJJB####&Y~Y7!~:                                        //
//                                          .^~!7JYPGBB?7BBGPYJ7!!^.                                          //
//                                             .:^~~!!7!!7!!~~^:.                                             //
//                                                   ......                                                   //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Ph is ERC1155Creator {
    constructor() ERC1155Creator("Phenomenon", "Ph") {}
}