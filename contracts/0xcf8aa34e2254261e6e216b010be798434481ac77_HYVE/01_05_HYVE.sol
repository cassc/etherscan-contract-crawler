// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HYVΞ EDITIONS
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
//           `^x{|!                                                                                               `^x{(:              //
//          \#@@@@@Q,                                                                                            v#@@@@@Q*            //
//         (@@@@@@@@O                                                                                           >@@@@@@@@@E-          //
//        [email protected]@@@@@@@@a                                                                                           *@@@@@@@@@@#^         //
//        [email protected]@@@@@@@@u                                                                                           .#[email protected]@@@@@@@@@y        //
//       :@@@@@@@@@8Y                                                                                           .B*[email protected]@@@@@@@@*       //
//       [email protected]@@@@@@@hli                                                                                           .B*l [email protected]@@@@@@@#`      //
//      :@@@@@@@@#_xx                                                                                           .B*l  [email protected]@@@@@@@{      //
//      [email protected]@@@@@@@s ^v_,-`                         .,-          -",`          `_"-               `-,:!:_          `^l  *@@@@@@@@$      //
//      [email protected]@@@@@@@Md#@@@@@QV"      !umKc=       'a#@@@@b_    rE#@@@@Qx`    `[email protected]@@@@O:  `_^xkPDQ#@@@@@@@@@q.        ^l  `#@@@@@@@@      //
//      [email protected]@@@@@@@@@@@@@@@@@@o`  `[email protected]@@@@@g.    `[email protected]@@@@@@Q. [email protected]@@@@@@@@D   [email protected]@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@D        ({  `[email protected]@@@@@@@      //
//      @@@@@@@@@@@@@@@@@@@@@#| {@@@@@@@@M   [email protected]@@@@@@@#[email protected]@@@@@@@@@@@r`[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@$`       vi  [email protected]@@@@@@@Q      //
//      @@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@` [email protected]@@@@@@@@[email protected]@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:        vi  [email protected]@@@@@@@U      //
//      [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y,#@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BMBG-d         =~ [email protected]@@@@@@@@_      //
//      [email protected]@@@@@@@@@@[email protected]#@@@@@@@@@@@@@@@@@@@@@@@@@@@@##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@QMc*:`  Q. w\ K           [email protected]@@@@@@@@u       //
//       [email protected]@@@@@@@@<  Q [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#)        Q. y* z         :[email protected]@@@@@@@@R        //
//       "g{P0#@@@L   g ^{[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Q#@@@@@@@@@@@#q\-    x` y* y      `([email protected]@@@@@@@@@V`        //
//       'z   `[email protected]!   g >(  ^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#iL<{@#@@@@@@@@@@@@@BM{):. V; y  .~YW#@@@@@@@@@@@v          //
//       `y    [email protected]:   g >(    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@M' v,xB "[email protected]@@@@@@@@@@@@@@@@@@##@@@@@@@@@@@@@@@@@k-           //
//       `L    MlB`   g >(      v#@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@B=   x,xP   `[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Bk.             //
//        x    Ml9    g >(       ,[email protected])=`[email protected]@@@@@@@@@@@@@@@Z*#xQ=B -*))[email protected]    x_v}      '*[email protected]@@@@@@@@@@@@@@@@@@@@@@@@#6|`               //
//        x    MlP    g ;(        ^O   >@@@@@@@@@@@@@@@@q  9<8"d      B!    x_vi          `[email protected]@@@@@@@@@@@@@@QWl!                   //
//        x    MlP    g !*        !O   [email protected]@@@@@@@@@@@@@@X   Z;g"O      g"    x_vi                -r#[email protected]#z{[email protected]                       //
//        `    MlP    g ,~        _Z  `@@@@@@@@@@@@@@@X    Z~8"M      B,    x.vi                  m! vU k   "@:                       //
//             MlP    g `.        _M  [email protected]@@@@@@@@@@@@@z     W!8"U      B,    x.vi                  P: xy {   '@=                       //
//             uvP    g           _M  [email protected]@@@@@@@@@@@@i      j'8"I      g"    ]-vi                  P: rw x   `@=                       //
//              :P    g           _M  [email protected]@@@@@@@@@@@|       I.8"I      d=    x.vL                  H: r{     `@"                       //
//              :P    g           _M  #@@@@@@@@@@#(        I.Q:I      W!    x..-                  P: r{     `#.                       //
//              :P    g           -P  [email protected]@@@@@@@@g-         o'8:^      W,    i-                    P: r{     `@"                       //
//              :P    g                I#@@@@@@I           w`g:       W,    Y-                    P: ~)     `@:                       //
//              :P    g                 `^[email protected]@`           L g:       W,    Y-                    P:        `#_                       //
//              :P    :                   Ye `g            | g:       W,    {_                    P:        `B`                       //
//              :P                        Lh `g              g:       Y.    {_                    P:        `D                        //
//              :P                        Lh `8              g:             {_                    P:        `O                        //
//              :P                        iU `g              8!             {_                    X_        `O                        //
//              :P                        LU  5              8!             {_                              `O                        //
//              :P                        r{  Z              3,             {_                              `O                        //
//              :P                            Z              V-             {"                               <                        //
//              :P                            Z              c-             {"                                                        //
//              :P                            Z              v`             {_                                                        //
//              -i                            M              `              {_                                                        //
//                                            h                             L-                                                        //
//                                            {                             (`                                                        //
//                                            .                             )`                                                        //
//                                                                          )`                                                        //
//                                                                          )`                                                        //
//                                                                          )`                                                        //
//                                                                          )`                                                        //
//                                                                          *`                                                        //
//                                                                                                                                    //
//                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HYVE is ERC1155Creator {
    constructor() ERC1155Creator() {}
}