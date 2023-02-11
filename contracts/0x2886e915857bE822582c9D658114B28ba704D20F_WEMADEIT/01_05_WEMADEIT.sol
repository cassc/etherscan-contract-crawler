// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WE MADE IT?
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//                                                      [email protected]      *8MV=                  //
//                                                      [email protected]@@@!    [email protected]@@@V                  //
//                                             `x}-     [email protected]@@@#lT}[email protected]@@@@;      `           //
//                                            r#@@@0(-v3#@@@@@@@@@@@@@@y!  "[email protected]:         //
//                        `  `Kz              `[email protected]@@@@@@@@@@QOPhXKZ$#@@@@@[email protected]@@@@O         //
//                      `[email protected];[email protected]@[email protected]           [email protected]@@@@@0]"          `*U#@@@@@@#v          //
//                   `r_`[email protected]@[email protected]@} .:        [email protected]@@@3_                `[email protected]@@@^           //
//                   )#@@B|       [email protected]@@[email protected]#[email protected]@@Q_                     [email protected]@@@),::=~`    //
//                    [email protected]`          [email protected]  #@@@@@@@@B`                       [email protected]@@@@@@@@i    //
//                  [email protected]@@V            @@#[email protected]@@@@!                         [email protected]@@@@@@Bw    //
//                  `,[email protected]           :@Br~'   )@@@$                          \@@@@y*.      //
//                   )[email protected]@5-        )#@#Y`   `[email protected]@@O                          *@@@#         //
//                   ;Vrr#@d}*=;|[email protected]|ke,[email protected]@@@@#`                         [email protected]@@#}!       //
//                      ,@@[email protected]@Kw#@i   [email protected]@@@@@@@@a                        [email protected]@@@@@@@D^    //
//                  `    ="  v#W  .).    [email protected]@@@u                      [email protected]@@@@@@@@_    //
//                 [email protected]~ `         '_v6BQZr    'I#@@@E!                  `[email protected]@@@z'-:=*~     //
//                 [email protected]@@[email protected]@B$P  ,!!:[email protected]@@@@@y "x\)#@@@@@dr`             "k#@@@@G            //
//                 [email protected]@@@@@@@B`yGx]}bd#@@@@@v:[email protected]@@@@@@@@@8e]*!,,:~(cd#@@@@@@@@z`          //
//                  #@@@@@@#IQT;[email protected]@@@@@@@@" >[email protected]@@Dx:[email protected]@@@@@@@@@@@@@@@#HP#@@@@g`         //
//                  [email protected]@@@@Z-VO`  [email protected]@@@@@[email protected]!   v?`     [email protected]@@@@[email protected]@@@@@_    r6#I_          //
//          ?8HT5d* [email protected]@DT- V#,   [email protected]@@@@@E -           `#@@@@<   :#@@@@_                   //
//          [email protected]@@@@@?yGrxXwQ8:    [email protected]@@@@@0       ~^;   _8#@#:     [email protected]@@@!                   //
//          }@@@@@@K *#@@@@@8)   [email protected]@@@@@x!Y.   :@@@-   .})_       =^,`                    //
//      ,*[email protected]@@@@@BT!,[email protected]@@@@@G   [email protected]@@@W*@@@T:*[email protected]@@G*:[email protected]@@r                               //
//     [email protected]@@@[email protected]@@@@d  xV3#@@@@@P   >#@@< [email protected]@@@@@@@@@@@@@@d                                //
//     [email protected]@@@3 [email protected]@@@M=!##c _)VMg#}  *#@#([email protected]@#P\,`   `:\M#@@s\wRQ~                          //
//    (@@@@@u `@@@@@#V)!~       _  [email protected]@@@@}`           `[email protected]@@@@Bi                          //
//    |@@@@@Y [email protected]@@@@r)VeGWaUu>`      [email protected]@#:               "#@@i                            //
//     [email protected]@@0` [email protected]@@@@@@@@@@@@@@@d'`_=*[email protected]@(                 [email protected]@9*!_`                        //
//      <0o`  [email protected]@@@@@@@@@@@@@@@@[email protected]@@@@@.                 '@@@@@@V                        //
//            }@@@@@@@@@@@@@@@QX._(}[email protected]@;                 [email protected]@QwY)_                        //
//             [email protected]@@@@@@@@#@@@@x      [email protected]@Q`               `[email protected]@*                            //
//              [email protected]@@@@#Ww*<!_     ^[email protected]@@@B=             ^[email protected]@@@Z=                          //
//                `"~!`i-          [email protected]#[email protected]@gx,       ,[email protected]@8U0#@Y                          //
//                  `~}m#B#Bq.      `    [email protected]@@@@[email protected]@@@@Z    `                           //
//                :3#@@@@@@@@*          [email protected]@@[email protected]@@[email protected]@@!                               //
//              [email protected]@@@@@@@@@@#          -LM>   [email protected]@@"   ~MY-                               //
//               :YM8#@@@@@@H-                  }VT                                       //
//                    `-_. \L                                                             //
//                      `[email protected]=                                                         //
//                   ,[email protected]@@@@@@@L;xv                                                      //
//                [email protected]@@@@@@@@@@@<~:                                                      //
//              `<xyR#@@@@@@@@@@P!                                                        //
//                    ':*|[email protected]@@@@@Z                                                       //
//                        `#@@@@@@@                                                       //
//                        ,@@@@@@@a                                                       //
//                        [email protected]@@@@@B'                                                       //
//                         [email protected]@@@3`                                                        //
//                         \@@M=                                                          //
//                         ,W_                                                            //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract WEMADEIT is ERC1155Creator {
    constructor() ERC1155Creator("WE MADE IT?", "WEMADEIT") {}
}