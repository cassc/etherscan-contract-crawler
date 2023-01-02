// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SNOWFALL
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//                                      .       [email protected]@@@+       .                                      //
//                                    .*@%-     [email protected]@@@+     :#@*.                                    //
//                                   [email protected]@@@@%-   [email protected]@@@+   :#@@@@@=                                   //
//                         :++++-     .*@@@@@%- [email protected]@@@+ :%@@@@@#:     :++++-                         //
//                         [email protected]@@@*       .*@@@@@%*@@@@##@@@@@#:       [email protected]@@@*                         //
//                         [email protected]@@@*         .*@@@@@@@@@@@@@@#:         [email protected]@@@*                         //
//                 [email protected]@+    [email protected]@@@*           .*@@@@@@@@@@#:           [email protected]@@@*    =%@+                 //
//               .%@@@@@+  [email protected]@@@*             .*@@@@@@#:             [email protected]@@@*  =%@@@@@:               //
//                 [email protected]@@@@@[email protected]@@@*           .+: [email protected]@@@+ :+:           [email protected]@@@*[email protected]@@@@@+                 //
//                   [email protected]@@@@@@@@@*         .*@@@#*@@@@*#@@@#.         [email protected]@@@@@@@@@*.                  //
//           ::::::::::#@@@@@@@@*  ====-  :#@@@@@@@@@@@@@@%-  :====. [email protected]@@@@@@@%-:::::::::           //
//           @@@@@@@@@@@@@@@@@@@# [email protected]@@@#    :#@@@@@@@@@@#:    [email protected]@@@- *@@@@@@@@@@@@@@@@@@@.          //
//           @@@@@@@@@@@@@@@@@@@@@*@@@@#      :#@@@@@@%-      [email protected]@@@*%@@@@@@@@@@@@@@@@@@@@.          //
//           :[email protected]@@@@@@@@#        [email protected]@@@*        [email protected]@@@@@@@@+----------------           //
//                         +***@@@@@@@@#        [email protected]@@@+        [email protected]@@@@@@@#***                         //
//        ..               %@@@@@@@@@@@@+      [email protected]@@@*.      [email protected]@@@@@@@@@@@@               .:        //
//      .*@@*.             #%%%%%%%%@@@@@@+:+%@@@@@@@@@@%*[email protected]@@@@@%%%%%%%%%             [email protected]@#:      //
//     .%@@@@@*.                     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@*.                     [email protected]@@@@@:     //
//       -%@@@@@*.      .*#:           *@@@@@@@@@@@@@@@@@@@@@@%.          .**:      [email protected]@@@@%=       //
//         -%@@@@@*.   *@@@@#:        [email protected]@@@@@@@@@@@@@@@@@@@@@@@+        .*@@@@#.  [email protected]@@@@@=         //
//           -%@@@@@*. :%@@@@@#:     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@-     .*@@@@@%-  [email protected]@@@@@=           //
//    ********#@@@@@@@#**@@@@@@@#****%@@@@@@@@@@@@@@@@@@@@@@@@@@%****#@@@@@@@#**@@@@@@@#********    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    #########@@@@@@@###@@@@@@@%####%@@@@@@@@@@@@@@@@@@@@@@@@@@@####%@@@@@@@###@@@@@@@#########    //
//           :%@@@@@#. :#@@@@@#:     :@@@@@@@@@@@@@@@@@@@@@@@@@@-     :#@@@@@%: .*@@@@@%-           //
//         :#@@@@@#:   #@@@@%-        [email protected]@@@@@@@@@@@@@@@@@@@@@@@*        :#@@@@#.  .*@@@@@%-         //
//       :#@@@@@#:      :*#-           *@@@@@@@@@@@@@@@@@@@@@@%           :##-      .*@@@@@%-       //
//     .%@@@@@#:                     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@+                     .*@@@@@%:     //
//      :#@@#:             *########%@@@@@*-*%@@@@@@@@@@@*[email protected]@@@@@#########             .*@@%-      //
//        ::               %@@@@@@@@@@@@+.     :[email protected]@@@*:.     [email protected]@@@@@@@@@@@@               .:        //
//                         *###@@@@@@@@#        [email protected]@@@+        [email protected]@@@@@@@####                         //
//           ::::::::::::::::=%@@@@@@@@#        [email protected]@@@+        [email protected]@@@@@@@@+::::::::::::::::           //
//           @@@@@@@@@@@@@@@@@@@@@*@@@@#      .*@@@@@@#:      [email protected]@@@#@@@@@@@@@@@@@@@@@@@@@.          //
//           @@@@@@@@@@@@@@@@@@@#[email protected]@@@#    .*@@@@@@@@@@#:    [email protected]@@@- *@@@@@@@@@@@@@@@@@@@.          //
//           :---------#@@@@@@@@*  ++++-  .*@@@@@@@@@@@@@@#:  -++++. [email protected]@@@@@@@%----------           //
//                   [email protected]@@@@@@@@@*         .#@@@%*@@@@##@@@#:         [email protected]@@@@@@@@@+                   //
//                 -%@@@@@*[email protected]@@@*           :*- [email protected]@@@+ :*-           [email protected]@@@*[email protected]@@@@@=                 //
//               .%@@@@@+. [email protected]@@@*             [email protected]@@@@@*.             [email protected]@@@*  [email protected]@@@@@:               //
//                 [email protected]@+.   [email protected]@@@*            [email protected]@@@@@@@@@*.           [email protected]@@@*    [email protected]@*.                //
//                  ..     [email protected]@@@*         [email protected]@@@@@@@@@@@@@*.         [email protected]@@@*      .                  //
//                         [email protected]@@@*       [email protected]@@@@@#@@@@#%@@@@@*.       [email protected]@@@*                         //
//                         :****-      [email protected]@@@@@= [email protected]@@@+ -%@@@@@*.     :****-                         //
//                                   [email protected]@@@@%=   [email protected]@@@+   -%@@@@@=                                   //
//                                    .*@@=     [email protected]@@@+     -%@#:                                    //
//                                      .       [email protected]@@@+       .                                      //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract KRGMN is ERC721Creator {
    constructor() ERC721Creator("SNOWFALL", "KRGMN") {}
}